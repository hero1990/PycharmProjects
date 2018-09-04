import os


class RenameFileCommand(object):
    def __init__(self, from_name, to_name):
        self._from = from_name
        self._to = to_name

    def execute(self):
        os.rename(self._from, self._to)

    def undo(self):
        os.rename(self._to, self._from)

class History(object):
    def __init__(self):
        self._commands = list()

    def execute(self, command):
        self._commands.append(command)
        command.execute()

    def undo(self):
        self._commands.pop.undo()


history = History()
history.execute(RenameFileCommand('docs/1.txt', 'docs/2.txt'))
history.execute(RenameFileCommand('docs/1c.txt', 'docs/2c.txt'))
history.undo()
history.undo()
