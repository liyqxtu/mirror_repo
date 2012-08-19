#!/usr/bin/env python
import os
import sys
import urllib2
import json
import re
from xml.etree import ElementTree

def exists_in_tree(lm, repository):
    for child in lm.getchildren():
        if child.attrib['name'].endswith(repository):
            return True
    return False

# in-place prettyprint formatter
def indent(elem, level=0):
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def add_to_manifest(repositories):
    try:
        lm = ElementTree.parse("github_mirror_manifest.xml")
        lm = lm.getroot()
    except:
        lm = ElementTree.Element("manifest")

    for repository in repositories:
        repo_name = repository['repository']
        repo_target = repository['target_path']
        if exists_in_tree(lm, repo_name):
            print '%s already exists' % (repo_name)
            continue
        if not repo_target is None:
		print "not_none"

        if repo_target is None :
		project = ElementTree.Element("project", attrib = {"name": "%s" % repo_name})

        if 'branch' in repository:
            project.set('revision',repository['branch'])

        lm.append(project)

    indent(lm, 0)
    raw_xml = ElementTree.tostring(lm)
    raw_xml = '<?xml version="1.0" encoding="UTF-8"?>\n' + raw_xml

    f = open('github_mirror_manifest.xml', 'w')
    f.write(raw_xml)
    f.close()


print "start"

github_users=["CyanogenMod","teamhacksung"]
for github_user  in  github_users:
	repositories = []

	page = 1

	while 1:
	    result = json.loads(urllib2.urlopen("https://api.github.com/users/%s/repos?page=%d" % (github_user,page)).read())
	    if len(result) == 0:
		break
	    for res in result:
		repositories.append(res)
	    page = page + 1

	print "middle"

	for repository in repositories:
	#        print repository
		repo_name = repository['full_name']
		print repo_name
		add_to_manifest([{'repository':repo_name,'target_path':None}])

#            print "Syncing repository to retrieve project."
#            os.system('repo sync %s' % repo_path)
#            print "Repository synced!"
#            fetch_dependencies(repo_path)
#            print "Done"
#            sys.exit()


