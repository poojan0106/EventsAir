public class ContactUtils {
    // Method to validate an email address using regex
    public static Boolean isValidEmail(String email) {
        // Regular expression pattern for email validation
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        
        // Compile the pattern
        Pattern pattern = Pattern.compile(emailRegex);
        
        // Match the email against the pattern
        Matcher matcher = pattern.matcher(email);
        
        // Return true if email matches the pattern, false otherwise
        return matcher.matches();
    }

    // Method to create and insert a new contact if email is valid
    public static void createContactIfValid(String firstName, String lastName, String email) {
        if(isValidEmail(email)) {

            system.debug('valid');
        } else {
            system.debug('not valid');
        }
    }
}