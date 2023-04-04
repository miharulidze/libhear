CXX = CC
MPICXX = CC
INCLUDE_DIR = $(shell pwd)/include/
SRC_DIR = $(shell pwd)/src/
TESTS_DIR = $(shell pwd)/tests/
DEBUG_FLAGS = -g -O0
RELEASE_FLAGS = -O3 -ffast-math -march=native -lcrypto -lssl
AES_FLAGS = -D AESNI=1 -maes -Wno-narrowing
TSC_FLAGS= -D TSC_PROF=1
LIBHEAR_CXX_FLAGS = -I$(INCLUDE_DIR)
LIBHEAR_OBJS = mpool.po encrypt.po hear.po

%.po: $(SRC_DIR)/%.cpp
	$(MPICXX) $(LIBHEAR_CXX_FLAGS) -fPIC -o $@ -c $<

libhear.so: $(LIBHEAR_OBJS)
	$(MPICXX) $(LIBHEAR_CXX_FLAGS) -fPIC -shared -o $@ $(LIBHEAR_OBJS)

hear_baseline : LIBHEAR_CXX_FLAGS += $(RELEASE_FLAGS) -D ALLREDUCE_BASELINE=1
hear_baseline : $(LIBHEAR_OBJS) libhear.so

hear_baseline_tsc : LIBHEAR_CXX_FLAGS += $(TSC_FLAGS)
hear_baseline_tsc : hear_baseline

hear_naive : LIBHEAR_CXX_FLAGS += $(RELEASE_FLAGS) $(AES_FLAGS)
hear_naive : $(LIBHEAR_OBJS) libhear.so

hear_naive_tsc : LIBHEAR_CXX_FLAGS += $(TSC_FLAGS)
hear_naive_tsc : hear_naive

hear_mpool_only : LIBHEAR_CXX_FLAGS += $(RELEASE_FLAGS) $(AES_FLAGS) -D USE_MPOOL=1
hear_mpool_only : $(LIBHEAR_OBJS) libhear.so

hear_mpool_only_tsc : LIBHEAR_CXX_FLAGS += $(TSC_FLAGS)
hear_mpool_only_tsc : hear_mpool_only

hear_release : LIBHEAR_CXX_FLAGS += $(RELEASE_FLAGS) -D USE_MPOOL=1 -D USE_PIPELINING=1
hear_release :  $(LIBHEAR_OBJS) libhear.so

hear_release_aes : LIBHEAR_CXX_FLAGS += $(AES_FLAGS)
hear_release_aes : hear_release

hear_release_aes_tsc : LIBHEAR_CXX_FLAGS += $(TSC_FLAGS)
hear_release_aes_tsc : hear_release_aes

hear_debug : LIBHEAR_CXX_FLAGS += $(DEBUG_FLAGS) -D DCHECK=1
hear_debug :  $(LIBHEAR_OBJS) libhear.so

encr_perf_test : LIBHEAR_CXX_FLAGS += $(RELEASE_FLAGS) $(AES_FLAGS)
encr_perf_test : encrypt.po $(TESTS_DIR)/encryption_perf.cpp
	$(CXX) $(LIBHEAR_CXX_FLAGS) -o $@ $(TESTS_DIR)/encryption_perf.cpp encrypt.po

debug: hear_debug

debug_aes: LIBHEAR_CXX_FLAGS += $(AES_FLAGS)
debug_aes: hear_debug

release : hear_release

release_aes: hear_release_aes

clean:
	rm -rf *.po src/*.po *.so encr_perf_test encr_perf_test_aes
