#!/bin/bash

GOAL=install
if [ x != x$1 ]; then
    GOAL=$1
fi

echo "Cleaning repo folder..."
git clean -fdx

echo "executing mvn $GOAL..."
(cd xtendsions && mvn $GOAL) && (cd xtendsionTest && mvn $GOAL)
