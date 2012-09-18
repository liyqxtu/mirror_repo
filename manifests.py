#!/usr/bin/env python
import os
import sys
import urllib2
import json
import re
from xml.etree import ElementTree

global  lm
lm = ElementTree.Element("manifest")

def exists_in_tree(lm, repository):
    for child in lm.getchildren():
        if not child.get("name") is None :
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

def manifest_head():
#    lm = ElementTree.Element("manifest")
    remote= ElementTree.Element("remote", attrib = {"name":"github","fetch":"https://github.com","review":"review.cyanogenmod.com"})
    default= ElementTree.Element("default", attrib = {"revision":"master","remote":"github","sync-j":"4"})
    lm.append(remote)
    lm.append(default)

def manifest_tail():
    indent(lm, 0)
    raw_xml = ElementTree.tostring(lm)
    raw_xml = '<?xml version="1.0" encoding="UTF-8"?>\n' + raw_xml
    f = open('github_mirror_manifest.xml', 'w')
    f.write(raw_xml)
    f.close()


print "start"

github_users=["CyanogenMod","teamhacksung"]
manifest_head()
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

manifest_tail()

