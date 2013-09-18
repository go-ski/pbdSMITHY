class R3Formula < Formula
  homepage "r-project.org"
  url "http://mirrors.nics.utk.edu/cran/src/base/R-3/R-3.0.1.tar.gz"
  
  def install
    module_list
    
    system "./configure \
      --prefix=$SW_BLDDIR \
      --enable-R-profiling \
      --enable-memory-profiling \
      --enable-R-shlib \
      --enable-BLAS-shlib \
      --enable-byte-compiled-packages \
      --enable-shared \
      --enable-long-double \
      --with-readline \
      --with-tcltk \
      --with-tcl-config=/sw/analysis-x64/tcl_tk/8.5.8/centos5.5_gcc4.1.2/install_dir/lib/tclConfig.sh \
      --with-tk-config=/sw/analysis-x64/tcl_tk/8.5.8/centos5.5_gcc4.1.2/install_dir/lib/tkConfig.sh \
      --with-cairo \
      --with-libpng \
      --with-jpeglib \
      --with-libtiff \
      --with-system-zlib \
      --with-system-bzlib \
      --with-system-pcre \
      --with-valgrind-instrumentation \
      --with-blas="$ACML_MPLIB" \
      --with-lapack"
