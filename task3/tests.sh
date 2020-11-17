#!/bin/bash


c++ -o factory hw3.cpp -lpthread
for i in {1..5}; do
    ./factory input/test$i.txt output/answer$i.txt
done
