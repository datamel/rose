# -*- coding: utf-8 -*-
#-----------------------------------------------------------------------------
# (C) British Crown Copyright 2012 Met Office.
#
# This file is part of Rose, a framework for scientific suites.
#
# Rose is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Rose is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Rose. If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------
"""A handler of file system locations."""

from hashlib import md5
import os
from tempfile import mkdtemp
from urlparse import urlparse
import xml.parsers.expat

class SvnLocHandler(object):
    """Handler of file system locations."""

    FCM = "fcm"
    SVN = "svn"
    SCHEME = SVN

    def __init__(self, manager):
        self.manager = manager
        self.svn = self.SVN
        if self.manager.popen.which(self.FCM):
            self.svn = self.FCM
        self.svn_info_xml_parser = SvnInfoXMLParser()

    def can_handle(self, loc):
        schemes = [self.SVN, "svn+ssh"]
        if self.svn == self.FCM:
            schemes.append(self.FCM)
        return (urlparse(loc.name).scheme in schemes or
                not os.exists(loc.name) and
                not self.manager.popen.run(self.svn, "info", loc.name)[0])

    def parse(self, loc):
        """Set loc.real_name, loc.scheme, loc.loc_type."""
        loc.scheme = self.SCHEME
        xml_str, err = self.manager.popen(self.svn, "info", "--xml", loc.name)
        info_entry = self.svn_info_xml_parser(xml_str)
        if info_entry["kind"] == "dir":
            loc.loc_type = loc.TYPE_TREE
        else: # if info_entry ["kind"] == "file":
            loc.loc_type = loc.TYPE_BLOB
        loc.real_name = "%s@%s" % (info_entry["url"], info_entry["revision"])
        loc.key = info_entry["commit:revision"]

    def pull(self, loc, work_dir):
        """If loc is in the file system, sets loc.cache to loc.name.

        Otherwise, raise an OSError.

        """
        if not loc.real_name:
            self.parse(loc)
        base_name = md5().update(loc.real_name).hexdigest()
        loc.cache = os.path.join(work_dir, base_name)
        self.manager.popen("svn", "export", "-q", loc.real_name, loc.cache)


class SvnInfoXMLParser(object):
    """An XML parser tailored for a single entry of "svn info --xml"."""

    def __init__(self):
        self.parser = xml.parsers.expat.ParserCreate()
        self.parser.StartElementHandler = self._handle_tag0
        self.parser.EndElementHandler = self._handle_tag1
        self.parser.CharacterDataHandler = self._handle_text

    def parse(self, text):
        """Parse text containing a valid XML document.

        Return a dict, where the keys represent full hierarchy of the values in
        the form "elements:..." or "elements:...:attr" and the values are the
        text value of the element or the attribute.

        """
        self.state = {"entry": {}, "index": None, "stack": []}
        self.parser.Parse(text)
        return self.state["entry"]

    __call__ = parse

    def _handle_tag0(self, name, attr_map):
        self.state["stack"].append(name)
        self.state["index"] = ":".join(self.state["stack"][2:])
        if self.state["entry"]:
            self.state["entry"][self.state["index"]] = ""
        for key, value in attr_map.items():
            name = key
            if self.state["index"]:
                name = self.state["index"] + ":" + key
            self.state["entry"][name] = value
    
    def _handle_tag1(self, name):
        self.state["stack"].pop()

    def _handle_text(self, text):
        if self.state["index"]:
            self.state["entry"][self.state["index"]] += text.strip()
