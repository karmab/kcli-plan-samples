rm -rf source.ign
kcli create plan -f source.yml
cp /tmp/source.ign .
kcli delete vm --yes source
kcli create plan -f builder.yml --wait
sleep 60
#kcli create vm -P iso=klive.iso
