# Sequence It

## Purpose

Simple commandline tool that builds and saves a PNG version of your text sequence diagram.
Uses the [websequencediagram](https://www.websequencediagrams.com/) API for conversion.

## Requirements

- Ruby any version
- Files need to be saved with a `.seq` or `.sequence` file extension.

## Basic Installation

After pulling the project, move the script to your desired location. `cd` into the path.
run: `ruby sequence_it.rb path/to/file.seq`

## Advanced usage

Add the following to your .bashrc or .zshrc
`seq() { ruby ~/path/to/sequence_it.rb "$@" }`
run: `seq path/to/file.sequence`
