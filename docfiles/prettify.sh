#!/bin/bash

# mkdir -p pretty
# cp gen/forsyde-atom* pretty/main.tex

echo "Initial processing"

for f in gen/ForSyDe-Atom*; do
file=$(basename $f)
# \href{#x}{[y]} -> \cite{y}
# \href{#x}{y} -> \hyperref[x]{y}
sed '
s|\\href{[^}]*}{\[\([^]]*\)\]}|\\cite{\1}|g
s|\\href{#\([^}]*\)}{\([^}]*\)}|\\hyperref[\1]{\2}|g
s|\\subsection{|\\subsubsection{|g
s|\\section{|\\subsection{|g
/^\\subsection{Bibliography}$/,$d
' gen/$file > pretty/$file
sed -i ':a;N;$!ba;s/\\haddockbeginconstrs\n\\end{tabulary}\\par//g' pretty/$file
sed -i ':a;N;$!ba;s/\\end{haddockdesc}\n\\begin{haddockdesc}//g' pretty/$file

lines=$(awk '/\\haddockbeginconstrs/{flag=1;next}/\\end{tabulary}/{flag=0}flag' pretty/$file)


while read -r line; do
    line=$(echo $line | sed 's/\\/\\\\/g')
    line=$(echo $line | sed 's/\[/\\\[/g')
    line=$(echo $line | sed 's/\]/\\\]/g')
    # echo "--->$line"
    newln=$line
    char="&"
    ntab=$(awk -F"${char}" '{print NF-1}' <<< "${line}")
    if [ "$ntab" -eq "0" ]; then
	newln="&&$newln"
    fi
    if [ "$ntab" -eq "1" ]; then
	newln="\\\\haddockdecltt{>}&$newln"
    fi
    if [[ ! -z "${line// }" && ! "$line" == *\\ ]]; then
    	newln="$newln\\\\\\\\"
    fi
    # echo "<<<<$newln"
    if [ "$line" != "$newln" ]; then
        newln=$(echo $newln | sed 's/&/\\&/g')
        sed -i "s/$line/$newln/g" pretty/$file
	# awk -v l="$line" -v nl="$newln" \
	#     'NR==1,/l/{sub(/l/, "nl")} 1' pretty/$file
        # sed -i '0,|'"$line"'|{s|'"$line"'|'"$newln"'|}' pretty/$file
    fi    
done <<< "$lines"
done


# grabbing methods
echo "Grabbing class methods"

files="ForSyDe-Atom ForSyDe-Atom-MoC ForSyDe-Atom-ExB ForSyDe-Atom-Utility-Plot"

function process() {
    methods=''
    while read data; do
	def=$(echo $data | sed  "s|'\([^']*\).*|\1|g" \
		     | sed 's|\[(||g' | sed 's|\"||g' \
		     | sed -e 's| |\\ |g' | sed 's|\\|\\\\|g' \
		     | sed 's|&|\\\\\\&|g'
	   )
	doc=$(echo $data | sed  "s|.*, '\([^']*\)'|\1|g" \
		     | sed 's|)\]||g'  | sed 's|\"||g'\
		     | sed 's|\[\([^]]*\)\]| \\cite{\1}|g'\
		     | sed 's|\\|\\\\|g' \
		     | sed 's|xe2x80x9c||g' | sed 's|xe2x80x9d||g'
	   	     # | sed 's|\*|\\*|g'  \
	   	     # | sed 's|\.|\\.|g'
		     # | sed 's|&|\\&|g' \
	   )
	def="\\\\item[\\\\begin{tabular}{@{}l}$def\\\\end{tabular}]"
        doc="\\\\haddockbegindoc\n$doc\\\\par\n"
        methods="$methods$def\n$doc\n"
	# echo "----->$data"
        # echo "<<<<<<$doc"
    done
    # echo $methods
    sed -i 's|\\haddockpremethods{}\\textbf{Methods}|\\haddockpremethods{}\\textbf{Methods}\n\\begin{haddockdesc}\n'"$methods"'\\end{haddockdesc}\n|g' pretty/$1.tex
}

for file in $files; do
    methods=$(python extmethod.py < html/$file.html)
    echo $methods | ruby -F"\\), \\(" -ane  'puts $F' | process $file
done


# post-processing
echo "Post-processing"

for f in gen/ForSyDe-Atom*; do
file=$(basename $f)
# \href{#x}{[y]} -> \cite{y}
# \href{#x}{y} -> \hyperref[x]{y}
sed -i '
s|-&-|-\\\&-|g
s|/&\\|/\\\&\\textbackslash|g
s|/\\&\\|/\\\&\\textbackslash|g
s|/\*\\|/\*\\textbackslash|g
s|/\.\\|/\.\\textbackslash|g
s|/\!\\|/\"\!\\textbackslash|g
s|/\!|/\"\!|g
s|/\*\^|/\*\"\^|g
' pretty/$file
done

# s|{\\char '"'"'46}|\\\&|g
# s|{\\char '"'"'134}|\\textbackslash|g


echo "Automatic prettifying done. Manually take care of the following:"
echo " * ForSyDe-Atom-ExB.tex          : remove textbackslash in header"
echo " * ForSyDe-Atom.tex              : remove extra instances"
echo " * ForSyDe-Atom-Utility-Plot.tex : remove extra instances"
