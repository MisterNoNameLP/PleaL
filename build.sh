#!/bin/bash

buildingDir="building"

echo "Prepare fragments dir"
cp LICENSE ${buildingDir}/fragments
cp src/*.lua ${buildingDir}/fragments
cp src/thirdParty/*.lua ${buildingDir}/fragments

echo "Build scripts"
cd $buildingDir
./mergeScripts.lua -i ./blueprints -f ./fragments -o ./release -OS

echo "Cleanup"
rm ./fragments/*.lua
rm ./fragments/LICENSE
cd ..

echo "Done"