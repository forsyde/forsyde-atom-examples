/^[^><*]/ || /^$/ {print; next}

/^</ {
  print "\\begin{interactive}"
  sub(/^< /,"")
  print
  rc = getline
  while(($0 ~ /^</) && (rc > 0)) {
    sub(/^< /,"")
    print
    rc = getline
  }
  print "\\end{interactive}\n"
}

/^>/ {
  print "\\begin{code}"
  sub(/^> /,"")
  print
  rc = getline
  while(($0 ~ /^>/) && (rc > 0)) {
    sub(/^> /,"")
    print
    rc = getline
  }
  print "\\end{code}\n"
}

/^*/ {
  print "\\begin{itemize}"
  sub(/^* /,"\\item ")
  print
  rc = getline
  while(($0 ~ /^*/) && (rc > 0)) {
    sub(/^* /,"\\item ")
    print
    rc = getline
  }
  print "\\end{itemize}\n"
}
