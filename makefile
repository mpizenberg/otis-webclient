BUILD_DIR = dist

# BUILD ################################

all : static elm

static :
	mkdir -p $(BUILD_DIR)
	cp -r src/static $(BUILD_DIR)

elm :
	elm make src/Main.elm --output $(BUILD_DIR)/static/js/Main.js

# CLEAN ################################

clean :
	rm -r $(BUILD_DIR)

# INSTALL ##############################

install :
	npm install
	elm package install --yes
