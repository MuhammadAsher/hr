/**
 * Response formatting middleware
 * Standardizes all API responses to have consistent structure:
 * {
 *   status: true/false,
 *   message: string,
 *   data: object/array
 * }
 */

const responseFormatter = (req, res, next) => {
  // Success response helper
  res.success = (data, message = 'Success', statusCode = 200) => {
    return res.status(statusCode).json({
      status: true,
      message,
      data: data || {}
    });
  };

  // Error response helper
  res.error = (message = 'Error occurred', statusCode = 500, errorDetails = null) => {
    const response = {
      status: false,
      message,
      error: getErrorType(statusCode),
      code: statusCode,
      data: {}
    };

    // Add error details if provided
    if (errorDetails) {
      response.data.details = errorDetails;
    }

    return res.status(statusCode).json(response);
  };

  // Validation error helper
  res.validationError = (errors, message = 'Validation failed') => {
    return res.status(400).json({
      status: false,
      message,
      error: 'Validation Error',
      code: 400,
      data: {
        details: errors
      }
    });
  };

  // Unauthorized error helper
  res.unauthorized = (message = 'Unauthorized access') => {
    return res.status(401).json({
      status: false,
      message,
      error: 'Unauthorized',
      code: 401,
      data: {}
    });
  };

  // Forbidden error helper
  res.forbidden = (message = 'Access forbidden') => {
    return res.status(403).json({
      status: false,
      message,
      error: 'Forbidden',
      code: 403,
      data: {}
    });
  };

  // Not found error helper
  res.notFound = (message = 'Resource not found') => {
    return res.status(404).json({
      status: false,
      message,
      error: 'Not Found',
      code: 404,
      data: {}
    });
  };

  next();
};

// Helper function to get error type based on status code
const getErrorType = (statusCode) => {
  switch (statusCode) {
    case 400:
      return 'Bad Request';
    case 401:
      return 'Unauthorized';
    case 403:
      return 'Forbidden';
    case 404:
      return 'Not Found';
    case 409:
      return 'Conflict';
    case 422:
      return 'Unprocessable Entity';
    case 429:
      return 'Too Many Requests';
    case 500:
      return 'Internal Server Error';
    case 502:
      return 'Bad Gateway';
    case 503:
      return 'Service Unavailable';
    default:
      return 'Error';
  }
};

module.exports = responseFormatter;
