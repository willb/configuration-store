import wallaby

# the "tagging" module patches the Wallaby client library with 
# support for tag operations
import tagging

def get_store():
    # We'll start by setting up a Wallaby client library session against
    # the broker on localhost
    from qmf.console import Session
    console = Session()
    console.addBroker()
    raw_store, = console.getObjects(_class="Store")
    store = wallaby.Store(raw_store, console)
    
    # call this method after the store client is initialized so that
    # the tagging library knows how to create missing groups
    tagging.setup(store)
    return store

