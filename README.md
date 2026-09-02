# Advanced Compiler Course - Homework 1

## Introduction

This initial homework is designed to introduce you to the Bril (Big Red Intermediate Language) project and to help you set up your development environment.
Bril is the intermediate representation (IR) that we will use extensively throughout this course.

## Getting Started

1. Clone this repository recursively to ensure you get the Bril submodule, and enter it:

```sh
git clone --recursive https://github.com/pipi-bear/NTU-AC-HW1-2026.git
cd NTU-AC-HW1-2026
```

2. Carefully read and follow the instructions in the [Bril README](https://github.com/sampsyo/bril/blob/4029dd7b6440074bc4dd5557022848ef378f978a/README.md).
This document contains information on how to build the Bril toolchain, which is essential for completing this homework.

3. Pull the homework image and start a container with the repository mounted:

```sh
docker pull pipibear1015/acd-hw1:2026
docker run -it --rm -v "$PWD":/home/student/hw pipibear1015/acd-hw1:2026
```

The image reproduces the grading environment: ubuntu-22.04 with git, Python 3, pip, Node.js, and Deno preinstalled.
The repository appears inside the container at `/home/student/hw`, which is the working directory of the shell you get.

## Assignment Task

You need to complete the [install_bril.sh](install_bril.sh) script. This script will set up the Bril environment by installing the necessary tools.

Here is what the script needs to do:

1. Install Flit.
   Flit simplifies the process of putting Python packages on PyPI, and is used for the Python tools in the Bril project.
2. Install the Bril tools:
   - `bril2json`: converts Bril programs from text to JSON format.
   - `bril2txt`: converts Bril programs from JSON back to text format.
   - `brili`: the Bril interpreter, which executes code from its JSON format.

   Install `bril2json` and `bril2txt` from the `bril-txt` directory, **not** from the `bril-rs` directory in the Bril project.

Deno, the runtime that `brili` runs on, is already installed in the homework image, so your script does not need to install it.
The script should ensure these tools are installed and accessible in the user's PATH.
It must work on any machine running the homework image, not just yours, and it must finish within 10 seconds.

## Verifying Your Work

Inside the container, run the verification script with your student ID:

```sh
bash verify_hw1.sh <student-id> test
```

The script first runs `timeout 10 bash install_bril.sh` and reports the elapsed time, then checks that the three Bril tools are reachable and runs a small Bril program through them.
A successful run ends with `FINAL RESULT: PASS`.

Note that the tools are installed inside the container, so they disappear when the container exits.
This is expected: every `docker run` gives you a fresh environment, and the verification script reinstalls the tools each time it runs.

## Submission

Follow the submission instructions in the homework handout on NTU COOL. In short, you upload three things:

1. the screenshot(s) of the `bash verify_hw1.sh <student-id> info` output,
2. the screenshot of the `bash verify_hw1.sh <student-id> test` output ending with `FINAL RESULT: PASS`,
3. your `install_bril.sh` script file.

During grading we re-run your submitted script in the same Docker image with the same 10 second limit, using this repository's directory layout.
