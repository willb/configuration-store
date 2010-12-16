from qmf.console import Session
import wallaby

# create a new console object
console = Session()

# connect to the broker (on localhost:5672, by default)
console.addBroker()

# find the QMF object for the wallaby service
raw_store, = console.getObjects(_class="Store")

# wrap it up in a client object
store = wallaby.Store(raw_store, console)

# now, interact with it!
node = store.addNode("barney.local.")

feature = store.addFeature("Example feature")
param = store.addParam("EXAMPLE_PARAM")

# most "options" arguments are indeed optional
feature.modifyParams("ADD", {"EXAMPLE_PARAM":"example value"})

store.getDefaultGroup().modifyFeatures("ADD", ["Example feature"])

node.getConfig()

# get documentation on a method
help(store.activateConfiguration)

store.activateConfiguration()

node.getConfig()

# access properties
node.name

# even object-valued ones
node.identity_group
