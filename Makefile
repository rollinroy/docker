DC = docker
DB = $(DC) build
D_REP = uwgac
OS_VERSION = 16.04
R_VERSION = 3.4.3
MKL_VERSION = 2018.1.163
DB_FLAGS =

# docker image names
DI_OS = $(DF_BASE_OS)-$(OS_VERSION)-hpc
DI_R = r-$(R_VERSION)-mkl
DI_APPS = apps
DI_TM_MASTER = topmed-master
DI_TM_DEVEL = topmed-devel

# docker files
DF_BASE_OS = ubuntu
DF_OS = $(DF_BASE_OS)-hpc.dfile
DF_APPS = apps.dfile
DF_R = r-mkl.dfile
DF_TM_MASTER = topmed-master.dfile
DF_TM_DEVEL = topmed-devel.dfile

# docker image tags
DT_OS = latest
DT_R = latest
DT_APPS = latest
DT_TM_MASTER = latest
DT_TM_DEVEL = latest

D_IMAGES = $(DI_OS) $(DI_APPS) $(DI_R) $(DI_TM_MASTER) $(DI_TM_DEVEL)
D_PUSH = $(addsuffix .push,$(D_IMAGES))
D_IMAGES_IMG = $(addsuffix .image,$(D_IMAGES))
.PHONY:  all

all: $(D_IMAGES_IMG)
	@echo ">>> Build is complete"

push: $(D_PUSH)
	@echo ">>> Push is complete"

$(DI_OS).image: $(DF_OS)
	@echo ">>> "Building $(D_REP)/$@:$(DT_OS)
	$(DB) -t $(D_REP)/$(DI_OS):$(DT_OS) $(DB_FLAGS) --build-arg base_os=$(DF_BASE_OS) \
        --build-arg mkl_version=$(MKL_VERSION) --build-arg itag=$(OS_VERSION) -f $(DF_OS) . > build_$(DI_OS).log
	touch $(DI_OS).image

$(DI_APPS).image: $(DF_APPS) $(DI_OS)
	@echo ">>> "Building $(D_REP)/$@:$(DT_APPS)
	$(DB) -t $(D_REP)/$(DI_APPS):$(DT_APPS) $(DB_FLAGS) \
        --build-arg base_name=$(DI_OS) \
        --build-arg itag=$(DT_OS) -f $(DF_APPS) . > build_$(DI_APPS).log
	touch $(DI_APPS).image

$(DI_R).image: $(DF_R) $(DI_APPS)
	@echo ">>> "Building $(D_REP)/$@:$(DT_R)
	$(DB) -t $(D_REP)/$(DI_R):$(DT_R) $(DB_FLAGS) \
        --build-arg r_version=$(R_VERSION) --build-arg base_name=$(DI_APPS) \
        --build-arg itag=$(DT_APPS) -f $(DF_R) . > build_$(DI_R).log
	touch $(DI_R).image

$(DI_TM_MASTER).image: $(DF_TM_MASTER) $(DI_R)
	@echo ">>> "Building $(D_REP)/$(DI_TM_MASTER):$(DT_TM_MASTER)
	$(DB) -t $(D_REP)/$(DI_TM_MASTER):$(DT_TM_MASTER) $(DB_FLAGS)  \
        --build-arg r_version=$(R_VERSION) --build-arg base_name=$(DI_R) \
        --build-arg itag=$(DT_R) -f $(DF_TM_MASTER) . > build_$(DI_TM_MASTER).log
	touch $(DI_TM_MASTER).image

$(DI_TM_DEVEL).image: $(DF_TM_DEVEL) $(DI_TM_MASTER)
	@echo ">>> "Building $(D_REP)/$@:$(DT_TM_DEVEL)
	$(DB) -t $(D_REP)/$(DI_TM_DEVEL):$(DT_TM_DEVEL) $(DB_FLAGS)  \
        --build-arg r_version=$(R_VERSION) --build-arg base_name=$(DI_TM_MASTER) \
        --build-arg itag=$(DT_TM_MASTER) -f $(DF_TM_DEVEL) . > build_$(DI_TM_DEVEL).log
	touch $(DI_TM_DEVEL).image


.SUFFIXES : .dfile2 .image .push

.image.push:
	@echo ">>> pushing $(D_REP)/$*"
#	$(DC) push $(D_REP)/$* > push_$*.log
	@touch $@

.dfile2.image:
	@echo ">>> building $(D_REP)/$*:$(D_TAG) $< "
	$(DB) -t $(D_REP)/$*:$(D_TAG) $(DB_FLAGS) -f $< . > build_$*.log
	@touch $@

clean:
	@echo Deleting all images $(D_IMAGES)
	@rm -f $(D_IMAGES_IMG)
	@echo Deleting all pushes $(D_PUSH)
	@rm -f $(D_PUSH)
