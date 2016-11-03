# Sequence It
## Purpose
Simple commandline tool that builds and saves a PNG version of your text sequence diagram.
Uses the [websequencediagram](https://www.websequencediagrams.com/) API for conversion.

## Requirements
Ruby any version
Files need to be saved with the `.sequence` file extension in order for correct parsing.

## Basic Installation
run: `ruby sequence_it.rb path/to/file`

## Advanced usage
Add the following  to your .bashrc or .zshrc
`seq() { ruby ~/path/to/sequence_it.rb "$@" }`
run: `seq path/to/file.sequence`

