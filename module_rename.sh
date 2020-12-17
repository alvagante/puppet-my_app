#!/bin/bash
OLDSTRING=$1
NEWSTRING=$2

if [ ! $1 ] ; then
    echo "Usage: $0 oldmodulename newmodulename"
    exit 1
fi
for file in $( grep -R "$OLDSTRING" . | grep -v ".git" | cut -d ":" -f 1 ) ; do
    # Detect OS
    if [ -f /System/Library/Accessibility/AccessibilityDefinitions.plist ] ; then
      sed -i "" -e "s/$OLDSTRING/$NEWSTRING/g" $file && echo "Changed $file"
    else
      sed -i "s/$OLDSTRING/$NEWSTRING/g" $file && echo "Changed $file"
    fi
done

mv apply/$1.pp apply/$2.pp
mv spec/classes/$1_spec.rb spec/classes/$2_spec.rb