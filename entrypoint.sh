#!/bin/bash

# convert swiftlint's output into GitHub Actions Logging commands
# https://help.github.com/en/github/automating-your-workflow-with-github-actions/development-tools-for-github-actions#logging-commands

function stripPWD() {
    if ! ${WORKING_DIRECTORY+false};
    then
        cd - > /dev/null
    fi
    sed -E "s/$(pwd|sed 's/\//\\\//g')\///"
}

function convertToGitHubActionsLoggingCommands() {
    sed -E 's/^(.*):([0-9]+):([0-9]+): (warning|error|[^:]+): (.*)/::\4 file=\1,line=\2,col=\3::\5/'
}

function parseOutputsParameters() {
   input_value=$( cat )
   violations=$(echo "$input_value" | grep -E '::warning|::error' -c)
   errors=$(echo "$input_value" | grep -E 'error' -c)
   echo "$input_value"
   echo "::set-output name=violations_count::$violations"
   echo "::set-output name=serious_violations_count::$errors"
}


if ! ${WORKING_DIRECTORY+false};
then
	cd ${WORKING_DIRECTORY}
fi

if ! ${DIFF_BASE+false};
then
	changedFiles=$(git --no-pager diff --name-only --relative FETCH_HEAD $(git merge-base FETCH_HEAD $DIFF_BASE) -- '*.swift')

	if [ -z "$changedFiles" ]
	then
		echo "No Swift file changed"
		exit
	fi
fi

echo "Using swiftlint version: `swiftlint --version`"
set -o pipefail && swiftlint "$@" -- $changedFiles | stripPWD | convertToGitHubActionsLoggingCommands | parseOutputsParameters
