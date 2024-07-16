int validateEmail(String? value) {
  // Check if the value is empty or null
  if (value == null || value.trim().isEmpty) {
    return 1; // Error code 1: Empty or null value
  }

  // Check if the value is a valid email address
  if (!RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$').hasMatch(value)) {
    return 2; // Error code 2: Invalid email format
  }

  return 0; // Return 0 to indicate the value is valid
}

int validateName(String? value) {
  // Check if the value is empty or null
  if (value == null || value.trim().isEmpty) {
    return 1;
  }

  // Check if the value contains any non-alphabetic characters
  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
    return 1;
  }

  return 0; // Return null to indicate the value is valid
}

int validateCNIC(String? value) {
  // Check if the value is empty or null
  if (value == null || value.trim().isEmpty) {
    return 1; // Error code 1: Empty or null value
  }

  // Check if the value is a valid CNIC format (e.g., 1234567890123)
  if (!RegExp(r'^\d{13}$').hasMatch(value)) {
    return 2; // Error code 2: Invalid CNIC format
  }

  return 0; // Return 0 to indicate the value is valid
}

int validateAddress(String? value) {
  // Check if the value is empty or null
  if (value == null || value.trim().isEmpty) {
    return 1; // Error code 1: Empty or null value
  }

  // Check if the address is at least 5 characters long
  if (value.length < 20) {
    return 2; // Error code 2: Address is too short
  }

  // You can add more specific checks based on your requirements

  return 0; // Return 0 to indicate the value is valid
}

int validateColor(String? value) {
  // Check if the value is empty or null
  if (value == null || value.trim().isEmpty) {
    return 1;
  }

  // Check if the value contains any non-alphabetic characters
  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
    return 1;
  }

  return 0; // Return null to indicate the value is valid
}

int validateEmptyFields(String? value) {
  // Check if the value is empty or null
  if (value == null || value.trim().isEmpty) {
    return 1;
  }
  return 0; // Return null to indicate the value is valid
}

String? validateDate(DateTime? date) {
  if (date == null) {
    return 'Please select a date';
  }
  return null;
}
