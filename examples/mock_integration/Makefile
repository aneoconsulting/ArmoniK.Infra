CURRENT_DIR:=$(shell pwd)
DIST_DIR?=$(shell pwd)/../../dist
BUILD_TYPE?=Release

.PHONY: clean all build-mock

all: build-mock


build-mock:
	cd HtcCommon && dotnet restore && dotnet add package -s $(DIST_DIR)/dotnet5.0/  HttpApi && dotnet add package -s $(DIST_DIR)/dotnet5.0/  HTCGridAPI 
	cd Client && dotnet add package -s $(DIST_DIR)/dotnet5.0/  HttpApi && dotnet add package -s $(DIST_DIR)/dotnet5.0/  HTCGridAPI 
	dotnet build --configuration $(BUILD_TYPE) .
	mkdir -p ./lib
	cp -v Client/bin/$(BUILD_TYPE)/net5.0/HtcCommon.dll ./lib
	dotnet pack -c $(BUILD_TYPE) -o $(DIST_DIR)/dotnet5.0
	

upload: build-mock
	$(MAKE) -C ./Server upload BUILD_TYPE=$(BUILD_TYPE)

clean:
	dotnet clean --configuration $(BUILD_TYPE) .
	rm -f ./lib/*.dll


