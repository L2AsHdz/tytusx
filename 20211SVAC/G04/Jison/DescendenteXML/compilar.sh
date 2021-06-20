#!/bin/zsh

echo compilando archivo jison...
jison AnalyzerXMLDescendente.jison
jison ../XPATH/jisonXpaht.jison
echo ----------------------------------------

echo traspilando archivos TypeScript
tsc
echo ----------------------------------------

echo moviendo archivo
mv AnalyzerXMLDescendente.js ../../js
mv jisonXpaht.js ../XPATH/
echo ----------------------------------------
