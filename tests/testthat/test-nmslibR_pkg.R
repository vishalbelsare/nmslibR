#========================================================================================

# helper function to skip tests if we don't have the 'foo' module
# https://github.com/rstudio/reticulate


skip_test_if_no_module <- function(MODULE) {                        # MODULE is of type character string ( length(MODULE) >= 1 )

  if (length(MODULE) == 1) {

    module_exists <- reticulate::py_module_available(MODULE)}

  else {

    module_exists <- sum(as.vector(sapply(MODULE, function(x) reticulate::py_module_available(x)))) == length(MODULE)
  }

  if (!module_exists) {

    testthat::skip(paste0(MODULE, " is not available for testthat-testing"))
  }
}

#===========================================================================================

# data
#-----

set.seed(1)
x = matrix(runif(1000), nrow = 100, ncol = 10)

x_lst = list(x, x)


# response regression
#--------------------

set.seed(3)
y_reg = runif(100)


# response "binary" classification
#---------------------------------

set.seed(4)
y_BINclass = sample(1:2, 100, replace = T)


# response "multiclass" classification
#-------------------------------------

set.seed(5)
y_MULTIclass = sample(1:3, 100, replace = T)


#===========================================================================================


context('tests for nmslibR pkg')




# conversion of an R matrix to a scipy sparse matrix
#---------------------------------------------------

testthat::test_that("the 'mat_2scipy_sparse' returns an error in case that the 'format' parameter is invalid", {

  skip_test_if_no_module("scipy")

  testthat::expect_error( mat_2scipy_sparse(x, format = 'invalid') )
})


testthat::test_that("the 'mat_2scipy_sparse' returns a scipy sparse matrix", {

  skip_test_if_no_module("scipy")

  res = mat_2scipy_sparse(x, format = 'sparse_row_matrix')

  cl_obj = class(res)[1]                                                             # class is python object

  same_dims = sum(unlist(reticulate::py_to_r(res$shape)) == dim(x)) == 2         # sparse matrix has same dimensions as input dense matrix

  testthat::expect_true( same_dims && cl_obj == "scipy.sparse.csr.csr_matrix"  )
})



# conversion of an R 'dgCMatrix' to a scipy sparse matrix
#--------------------------------------------------------

testthat::test_that("the 'dgCMatrix_2scipy_sparse' returns an error in case that the input object is not of type 'dgCMatrix'", {

  skip_test_if_no_module("scipy")

  mt = matrix(runif(20), nrow = 5, ncol = 4)

  testthat::expect_error( dgCMatrix_2scipy_sparse(mt) )
})


testthat::test_that("the 'dgCMatrix_2scipy_sparse' returns the correct output", {

  skip_test_if_no_module("scipy")

  data = c(1, 0, 2, 0, 0, 3, 4, 5, 6)

  dgcM = Matrix::Matrix(data = data, nrow = 3,

                        ncol = 3, byrow = TRUE,

                        sparse = TRUE)

  res = dgCMatrix_2scipy_sparse(dgcM)

  cl_obj = class(res)[1]                                                             # class is python object

  validate_dims = sum(dim(dgcM) == unlist(reticulate::py_to_r(res$shape))) == 2      # sparse matrix has same dimensions as input R sparse matrix

  testthat::expect_true( validate_dims && cl_obj == "scipy.sparse.csc.csc_matrix" )
})



# tests for 'NMSlib' class
#-------------------------


testthat::test_that("the NMSlib class works with default settings", {

  skip_test_if_no_module('nmslib')

  init_nms = NMSlib$new(input_data = x, Index_Params = NULL, Time_Params = NULL, space='l1', space_params = NULL,

                        method = 'hnsw', data_type = 'DENSE_VECTOR', dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE)

  knns = 5

  tmp_res = init_nms$Knn_Query(x[1, ], k = knns)



  testthat::expect_true( inherits(tmp_res, 'list') && length(tmp_res) == 2 && all(unlist(lapply(tmp_res, length)) == knns) )
})



testthat::test_that("the NMSlib class works with default settings [ and 'input_data' is a list ]", {

  skip_test_if_no_module('nmslib')

  init_nms = NMSlib$new(input_data = x_lst, Index_Params = NULL, Time_Params = NULL, space='l1', space_params = NULL,

                        method = 'hnsw', data_type = 'DENSE_VECTOR', dtype = 'DOUBLE', index_filepath = NULL, print_progress = FALSE)

  knns = 5

  tmp_res = init_nms$Knn_Query(x[2, ], k = knns)

  testthat::expect_true( inherits(tmp_res, 'list') && length(tmp_res) == 2 && all(unlist(lapply(tmp_res, length)) == knns) )
})


testthat::test_that("the NMSlib class works with default settings [ and 'Time_Params' is a list of parameters ]", {

  skip_test_if_no_module('nmslib')

  TIME_PARAMS = list(efSearch = 50)

  init_nms = NMSlib$new(input_data = x, Index_Params = NULL, Time_Params = TIME_PARAMS, space='l1', space_params = NULL,

                        method = 'hnsw', data_type = 'DENSE_VECTOR', dtype = 'DOUBLE', index_filepath = NULL, print_progress = FALSE)

  knns = 5

  tmp_res = init_nms$knn_Query_Batch(x, k = knns)

  testthat::expect_true( inherits(tmp_res, 'list') && length(tmp_res) == 2 && sum(unlist(lapply(tmp_res, function(x) inherits(x, 'matrix')))) == 2 &&
                           sum(unlist(lapply(tmp_res, function(x) ncol(x) == knns))) == 2)
})




# tests for 'KernelKnn_nmslib' function
#--------------------------------------


testthat::test_that("the KernelKnn_nmslib function works with default settings [ regression ]", {

  skip_test_if_no_module('nmslib')

  tmp_knn = KernelKnn_nmslib(data = x, TEST_data = NULL, y = y_reg, k = 5, h = 1.0, weights_function = NULL, Levels = NULL, Index_Params = NULL,

                             Time_Params = NULL, space='l1', space_params = NULL, method = 'hnsw', data_type = 'DENSE_VECTOR',

                             dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE, num_threads = 1)

  testthat::expect_true( inherits(tmp_knn, 'numeric') && length(tmp_knn) == nrow(x) )
})



testthat::test_that("the KernelKnn_nmslib function works with default settings [ binary classification ]", {

  skip_test_if_no_module('nmslib')

  tmp_knn = KernelKnn_nmslib(data = x, TEST_data = NULL, y = y_BINclass, k = 5, h = 1.0, weights_function = NULL, Levels = sort(unique(y_BINclass)), Index_Params = NULL,

                             Time_Params = NULL, space='l1', space_params = NULL, method = 'hnsw', data_type = 'DENSE_VECTOR',

                             dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE, num_threads = 1)

  testthat::expect_true( inherits(tmp_knn, 'matrix') && nrow(tmp_knn) == nrow(x) && ncol(tmp_knn) == length(unique(y_BINclass)) )
})



testthat::test_that("the KernelKnn_nmslib function works with default settings [ binary classification AND TEST_data is not NULL ]", {

  skip_test_if_no_module('nmslib')

  set.seed(2)
  samp = sample(1:nrow(x), round(0.8 * nrow(x)))
  samp_ = setdiff(1:nrow(x), samp)

  tmp_knn = KernelKnn_nmslib(data = x[samp, ], TEST_data = x[samp_, ], y = y_BINclass[samp], k = 5, h = 1.0, weights_function = NULL,

                             Levels = sort(unique(y_BINclass)), Index_Params = NULL, Time_Params = NULL, space='l1', space_params = NULL,

                             method = 'hnsw', data_type = 'DENSE_VECTOR', dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE,

                             num_threads = 1)

  testthat::expect_true( inherits(tmp_knn, 'matrix') && nrow(tmp_knn) == nrow(x[samp_, ]) && ncol(tmp_knn) == length(unique(y_BINclass)) )
})



testthat::test_that("the KernelKnn_nmslib function works with default settings [ multiclass classification ]", {

  skip_test_if_no_module('nmslib')

  tmp_knn = KernelKnn_nmslib(data = x, TEST_data = NULL, y = y_MULTIclass, k = 5, h = 1.0, weights_function = 'uniform', Levels = sort(unique(y_MULTIclass)), Index_Params = NULL,

                             Time_Params = NULL, space='l1', space_params = NULL, method = 'hnsw', data_type = 'DENSE_VECTOR',

                             dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE, num_threads = 1)

  testthat::expect_true( inherits(tmp_knn, 'matrix') && nrow(tmp_knn) == nrow(x) && ncol(tmp_knn) == length(unique(y_MULTIclass)) )
})



# tests for 'KernelKnnCV_nmslib' function
#----------------------------------------


testthat::test_that("the KernelKnnCV_nmslib function works with default settings [ regression ]", {

  skip_test_if_no_module('nmslib')

  FOLDS = 4

  tmp_knn = KernelKnnCV_nmslib(data = x, y = y_reg, k = 5, folds = FOLDS, h = 1.0, weights_function = NULL, Levels = NULL, Index_Params = NULL,

                               Time_Params = NULL, space='l1', space_params = NULL, method = 'hnsw', data_type = 'DENSE_VECTOR',

                               dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE, num_threads = 1, seed_num = 1)

  testthat::expect_true( inherits(tmp_knn, 'list') && names(tmp_knn) %in% c("preds", "folds") && all(as.vector(unlist(lapply(tmp_knn, function(x) lapply(x, function(y) length(y))))) == nrow(x) / FOLDS) )
})


testthat::test_that("the KernelKnnCV_nmslib function works with default settings [ classification ]", {

  skip_test_if_no_module('nmslib')

  FOLDS = 4

  tmp_knn = KernelKnnCV_nmslib(data = x, y = y_BINclass, k = 5, folds = FOLDS, h = 1.0, weights_function = NULL, Levels = sort(unique(y_BINclass)), Index_Params = NULL,

                               Time_Params = NULL, space='l1', space_params = NULL, method = 'hnsw', data_type = 'DENSE_VECTOR',

                               dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE, num_threads = 1, seed_num = 1)

  testthat::expect_true( inherits(tmp_knn, 'list') && names(tmp_knn) %in% c("preds", "folds") &&
                           all(as.vector(unlist(lapply(tmp_knn$preds, function(y) nrow(y)))) == nrow(x) / FOLDS) &&
                           all(as.vector(unlist(lapply(tmp_knn$folds, function(y) length(y)))) == nrow(x) / FOLDS))
})




# sparse datasets
#----------------


testthat::test_that("the NMSlib class works with sparse data in case of 'knn_Query_Batch' [ specify as data_type a 'SPARSE_VECTOR' ]", {

  skip_test_if_no_module(c('nmslib', 'scipy'))

  sparse_x = mat_2scipy_sparse(x, format = 'sparse_row_matrix')

  init_nms = NMSlib$new(input_data = sparse_x, Index_Params = NULL, Time_Params = NULL, space='l1', space_params = NULL,

                        method = 'hnsw', data_type = 'SPARSE_VECTOR', dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE)

  knns = 5

  tmp_res = init_nms$knn_Query_Batch(sparse_x, k = knns)                    # it would be tricky to do the same with "Knn_Query" as it will require firstly a python object as input and secondly a sparse unit

  testthat::expect_true( inherits(tmp_res, 'list') && length(tmp_res) == 2 && all(unlist(lapply(tmp_res, ncol)) == knns) )
})



testthat::test_that("the KernelKnn_nmslib function works with sparse data in case of regression [ specify as data_type a 'SPARSE_VECTOR' ]", {

  skip_test_if_no_module(c('nmslib', 'scipy'))

  sparse_x = mat_2scipy_sparse(x, format = 'sparse_row_matrix')

  tmp_knn = KernelKnn_nmslib(data = sparse_x, TEST_data = NULL, y = y_reg, k = 5, h = 1.0, weights_function = NULL, Levels = NULL, Index_Params = NULL,

                             Time_Params = NULL, space='l1', space_params = NULL, method = 'hnsw', data_type = 'SPARSE_VECTOR',

                             dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE, num_threads = 1)

  testthat::expect_true( inherits(tmp_knn, 'numeric') && length(tmp_knn) == unlist(reticulate::py_to_r(sparse_x$shape))[1] )
})


#=================================================================================================================================================================================

#---------------------------------------------------------
# THE FOLLOWING TWO FUNCTIONS DO NOT WORK WITH SPARSE DATA        [ probably it has to do with indexing, after I split the data in two or more parts ]
#---------------------------------------------------------


# testthat::test_that("the NMSlib class works with sparse data in case of 'Knn_Query' [ specify as data_type a 'SPARSE_VECTOR' ]", {
#
#   skip_test_if_no_module(c('nmslib', 'scipy'))
#
#   sparse_x = mat_2scipy_sparse(x, format = 'sparse_row_matrix')
#
#   init_nms = NMSlib$new(input_data = sparse_x, Index_Params = NULL, Time_Params = NULL, space='l1', space_params = NULL,
#
#                         method = 'hnsw', data_type = 'SPARSE_VECTOR', dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE)
#
#   knns = 5
#
#   tmp_res = init_nms$Knn_Query( sparse_x$getrow(1), k = knns)                                                                                    # use 'getrow() to subset the sparse matrix  [ DOES NOT WORK ]
#
#   testthat::expect_true( inherits(tmp_res, 'list') && length(tmp_res) == 2 && all(unlist(lapply(tmp_res, ncol)) == knns) )
# })




# testthat::test_that("the KernelKnnCV_nmslib function works with sparse data in case of classification [ specify as data_type a 'SPARSE_VECTOR' ]", {
#
#   skip_test_if_no_module(c('nmslib', 'scipy'))
#
#   dgcM = Matrix::Matrix(data = sample(c(rep(0.0, 5), runif(2)), 1000, replace = T), nrow = 100,
#
#                         ncol = 10, byrow = TRUE,
#
#                         sparse = TRUE)
#
#   FOLDS = 4
#
#   tmp_knn = KernelKnnCV_nmslib(data = dgcM, y = y_BINclass, k = 5, folds = FOLDS, h = 1.0, weights_function = NULL, Levels = sort(unique(y_BINclass)),              # splitting the dgcM internally and creating scipy-sparse sub-matrices returns an error when inputing to the function
#
#                                Index_Params = NULL, Time_Params = NULL, space='l1', space_params = NULL, method = 'hnsw', data_type = 'SPARSE_VECTOR',
#
#                                dtype = 'FLOAT', index_filepath = NULL, print_progress = FALSE, num_threads = 1, seed_num = 1)
#
#   testthat::expect_true( inherits(tmp_knn, 'list') && names(tmp_knn) %in% c("preds", "folds") &&
#                            all(as.vector(unlist(lapply(tmp_knn$preds, function(y) nrow(y)))) == nrow(x) / FOLDS) &&
#                            all(as.vector(unlist(lapply(tmp_knn$folds, function(y) length(y)))) == nrow(x) / FOLDS))
# })


#=================================================================================================================================================================================
