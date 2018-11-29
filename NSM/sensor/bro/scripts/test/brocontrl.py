import BroControl.plugin
from BroControl import config

class Foo(BroControl.plugin.Plugin):
    def __init__(self):
        super(Foo, self).__init__(apiversion=1)

    def name(self):
        return "foo"

    def pluginVersion(self):
        return 1

    def init(self):
        self.message("foo plugin is initialized")
        return True
