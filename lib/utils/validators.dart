class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  static String? positiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  static String? minLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    return null;
  }

  static String? maxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName must be no more than $maxLength characters long';
    }
    
    return null;
  }

  static String? range(String? value, double min, double max, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }
    
    return null;
  }

  static String? licensePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License plate is required';
    }
    
    // Basic validation - can be customized based on regional requirements
    if (value.trim().length < 3 || value.trim().length > 10) {
      return 'License plate must be between 3 and 10 characters';
    }
    
    return null;
  }

  static String? licenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License number is required';
    }
    
    if (value.trim().length < 5) {
      return 'License number must be at least 5 characters';
    }
    
    return null;
  }

  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}