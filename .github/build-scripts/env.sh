GITHUB_DIR=$(dirname $(pwd))
export PATH_TO_PLUGIN=`dirname ${GITHUB_DIR}`
export TESTSPACE=$PATH_TO_PLUGIN/testspace
export PATH_TO_REDMINE=$TESTSPACE/redmine
export RAILS_ENV=test