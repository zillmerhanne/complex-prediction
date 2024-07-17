import os

include: "helpers.smk"
TOOL_DIR = "tools"
## preprocess:
##    Preprocess the input JSON files.
##
rule preprocess:
  """When the sequences are too long to predict, cut them

  Note not yet implemented yet
  """
  input:
    "data/{protein_complex}.json"
  output:
    "results/data/{protein_complex}/{protein_complex}.json"
  shell:
    """
    cp {input} {output}
    """


## produce_fasta_pair:
##    Convert the json's to fasta inputs.
##
checkpoint produce_fasta_pairs:
  """Make the fasta for larger subunit pairs
  """
  conda: "../envs/CombFold.yml"
  input:
    "results/data/{protein_complex}/{protein_complex}.json",
    "results/.checkpoints/installed_CombFold"
  output:
    directory("results/data/{protein_complex}/subunits/fasta-pairs/")
  shell:
    """
    python3 {TOOL_DIR}/CombFold/scripts/prepare_fastas.py {input[0]} \
      --stage pairs --output-fasta-folder {output[0]} \
      --max-af-size 1800
    """


## produce_fasta_groups:
##    Determine which higher order-groups are most usefull to predict models
##    for.
##
checkpoint produce_fasta_groups:
  conda: "../envs/CombFold.yml"
  input:
    "results/data/{protein_complex}/{protein_complex}.json",
    "results/data/{protein_complex}/subunits/pair-pdb",
    "results/.checkpoints/installed_CombFold"
  output:
    directory("results/data/{protein_complex}/subunits/fasta-groups/")
  shell:
    """
    python3 {TOOL_DIR}/CombFold/scripts/prepare_fastas.py {input[0]} \
      --stage groups --output-fasta-folder {output[0]} \
      --max-af-size 1800 \
      --input-pairs-results {input[1]}
    """

## combfold:
##    Calculate the protein complexes from the (higher order) pairs
##    predicted by the colabfold steps.
##
checkpoint combfold:
  """Run the combfold programme

  Note --- If a high scoring assembly cannot be found, the programme will
            exit with a nonzero exit code. That is why the usage of
            `set +e` is needed.
  """
  conda: "../envs/CombFold.yml"
  input:
    "results/.checkpoints/installed_CombFold",
    json="results/data/{protein_complex}/{protein_complex}.json",
    pdb="results/data/{protein_complex}/subunits/pdb"
  output:
    directory("results/data/{protein_complex}/combfold")
  resources:
    mem_mb=12000
  threads: 15
  shell:
    """
    mkdir {output} -p
    set +e
    python3  {TOOL_DIR}/CombFold/scripts/run_on_pdbs.py {input.json}  \
      {input.pdb} {output}
    """

def get_combfold_structures(wildcards):
  output_folder = checkpoints.combfold.get(**wildcards).output[0]
  pdbs = [f for f in os.listdir(output_folder) if 
    f.endswith(".pdb") or f.endswith("cif")]
  return pdb

