#!/usr/bin/env bash

# "vifm session strategy"
#
# Restores a vifm session from the command line arguments.
# vifm can be run from command line in particular session,
# e.g. `vifm -c "session foo"`.
# NOTE: the strategy doesn't work if a session is created/changed
#       in vifm, e.g. `:session bar` vifm command

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

main() {
   local in_arg=0
   local in_quote=0
   local cmd=""
   for word in $ORIGINAL_COMMAND; do
      if [[ $word == -* ]]; then
         if [[ $in_quote -eq 1 ]]; then
            cmd+="\""
            in_quote=0
         fi
         in_arg=1
         cmd+=" $word"
         continue;
      fi

      if [[ $in_arg -eq 0 ]]; then
         cmd+=" $word"
         continue
      fi

      if [[ $in_quote -eq 0 ]]; then
         cmd+=" \"$word"
         in_quote=1
      else
         cmd+=" $word"
      fi

   done

   if [[ $in_quote -eq 1 ]]; then
      cmd+="\""
   fi

   echo $cmd
}
main

