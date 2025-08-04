#!/usr/bin/env python3
"""
Merge EsViritu results from multiple samples
Adapted from the original esviritu.py script
"""

import os
import pandas as pd
from pathlib import Path

def merge_esviritu_results(input_files, output_file):
    """
    Merge EsViritu results from multiple samples into a single Excel file
    
    Args:
        input_files: List of paths to EsViritu result TSV files
        output_file: Path to output Excel file
    """
    
    # Initialize empty DataFrame to store concatenated data
    stack_table = None
    
    # Process each input file
    for i, file_path in enumerate(input_files):
        print(f"Processing file {i+1}/{len(input_files)}: {file_path}")
        
        # Read the TSV file into a DataFrame
        try:
            df = pd.read_csv(file_path, sep="\t")
            
            # If it's the first file, initialize stack_table
            if stack_table is None:
                stack_table = df
            else:
                # Concatenate with existing data
                stack_table = pd.concat([stack_table, df], ignore_index=True)
                
        except Exception as e:
            print(f"Warning: Could not process {file_path}: {e}")
            continue
    
    if stack_table is None or stack_table.empty:
        print("No valid data found in input files")
        return
    
    # Extract sample number from sample_ID and sort
    if "sample_ID" in stack_table.columns:
        try:
            # Handle different sample ID formats
            def extract_sample_num(sample_id):
                if "_" in str(sample_id):
                    parts = str(sample_id).split("_")
                    # Try to find a numeric part
                    for part in reversed(parts):
                        if part.isdigit():
                            return int(part)
                    return 0
                else:
                    return 0
                    
            stack_table["sample_num"] = stack_table["sample_ID"].apply(extract_sample_num)
            stack_table_sort = stack_table.sort_values(by=["sample_num"])
        except Exception as e:
            print(f"Warning: Could not sort by sample number: {e}")
            stack_table_sort = stack_table
    else:
        stack_table_sort = stack_table
    
    # Create deduplicated table with unique accessions
    dedup_columns = ['accession', 'sequence_name', 'taxid', 'kingdom', 'phylum',
                     'class', 'order', 'family', 'genus', 'species']
    
    # Only use columns that exist in the data
    available_columns = [col for col in dedup_columns if col in stack_table.columns]
    
    if 'accession' in stack_table.columns:
        dereplicate_table = stack_table.drop_duplicates(subset=["accession"])[available_columns]
        
        # Create wide format table if possible
        if "sample_ID" in stack_table.columns and "RPKMF" in stack_table.columns:
            try:
                # Sort samples by sample number
                sample_order = sorted(stack_table["sample_ID"].unique(), 
                                    key=lambda x: extract_sample_num(x))
                
                # Create pivot table
                wide_table = stack_table_sort.pivot_table(
                    index="accession", 
                    columns="sample_ID", 
                    values="RPKMF", 
                    fill_value=0
                )
                
                # Reorder columns
                wide_table = wide_table[sample_order] if set(sample_order).issubset(wide_table.columns) else wide_table
                
                # Merge with dereplicate table
                merge_table = pd.merge(dereplicate_table, wide_table, 
                                     left_on="accession", right_on="accession", how="left")
            except Exception as e:
                print(f"Warning: Could not create wide format table: {e}")
                merge_table = dereplicate_table
        else:
            merge_table = dereplicate_table
    else:
        merge_table = stack_table_sort
    
    # Save results to Excel file
    try:
        with pd.ExcelWriter(output_file, engine="openpyxl") as writer:
            if 'merge_table' in locals():
                merge_table.to_excel(writer, sheet_name="merge_table", index=False)
            stack_table_sort.to_excel(writer, sheet_name="stack_table", index=False)
        
        print(f"Results saved to: {output_file}")
        print(f"Total samples processed: {len(input_files)}")
        print(f"Total rows in combined data: {len(stack_table_sort)}")
        
    except Exception as e:
        print(f"Error saving Excel file: {e}")
        # Save as CSV backup
        csv_file = output_file.replace('.xlsx', '_backup.csv')
        stack_table_sort.to_csv(csv_file, index=False)
        print(f"Saved backup CSV to: {csv_file}")

if __name__ == "__main__":
    # Get input files from Snakemake
    input_files = snakemake.input.results
    output_file = snakemake.output.merged
    
    merge_esviritu_results(input_files, output_file)