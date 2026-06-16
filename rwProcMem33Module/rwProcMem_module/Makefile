ifneq ($(KERNELRELEASE),)
obj-m += rwProcMem_module.o
else
KERNEL_SRC ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

modules:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) \
		O=$(O) LLVM=$(LLVM) DEPMOD=$(DEPMOD) \
		INSTALL_MOD_PATH=$(INSTALL_MOD_PATH) \
		INSTALL_MOD_STRIP=$(INSTALL_MOD_STRIP) modules

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) \
		O=$(O) LLVM=$(LLVM) DEPMOD=$(DEPMOD) \
		INSTALL_MOD_PATH=$(INSTALL_MOD_PATH) \
		INSTALL_MOD_STRIP=$(INSTALL_MOD_STRIP) modules_install

clean:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) O=$(O) clean

all: modules

.PHONY: all modules modules_install clean
endif
