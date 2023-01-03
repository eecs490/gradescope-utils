READ.ME(1)                  EECS 490 Gradescope Utilities                  READ.ME(1)

NAME
       EECS 490 Gradescope Utilities

DESCRIPTION
       Collection of scripts for gradescope stuff

       Each file should contain its own documentation

       Below is just a overview

       originally a port of <https://github.com/eecs490/Assignment-8-Gradescope>
       during W22

   bin
       The main scripts, in pipeline order:

       join.pl : zip X (json, json)
           csv is single csv of all submissions

           returns a json pair, (token2uniqname, submissions), where submissions is
           keyed by token

           Intended for converting a Gradescope submissions export into json

       csv2json : csv X json
           "Text::CSV" wrapper that converts csv to key-value

           Intended for converting a csv token2uniqname into json, as an initial step
           for split.pl

       split.pl : (json, csv) X json
           Takes token2uniqname json and splits csv into json key-value, keyed by
           token

           Intended for processing a csv database dump

       map.pl : json X json
           This is where ``the real" processing is hooked in

       upload.pl : (json, json) X ()
           Takes a json pair, (token2uniqname, submissions), and uploads to
           Gradescope

   lib
       Perl modules

DEPENDENCIES
       non-exhaustive list of external programs

   runtime
       unzip(1), curl(1), bat(1)

   build
       dzil(1)

SEE ALSO
       json_pp(1)

Winter 2023                           2023-01-03                           READ.ME(1)
