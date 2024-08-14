public class ResponseWrapper {
    
    public class ContactPhoneNumbers {    
        public String mobile;
    }
    
     public class primaryAddress  {    
        public String city;
         public String country;
         public String line1;
         public String line2;
         public String line3;
         public String postCode;
         public String state;
    }
    
    public class Contact {
        public String id;
        public String lastName;
        public String firstName;
        public String title;
        public Datetime checkInDate;
        public Datetime checkOutDate;
        public String organizationName;
        public String primaryEmail;
        public ContactPhoneNumbers contactPhoneNumbers;
        public primaryAddress primaryAddress;
        public List<Registration> registrations;
        List<FunctionRegistration> functionRegistrations;
        List<CustomField> customFields;
        List<EventMarketingRecord> marketingRecords;
        Datetime lastModifiedAt;
    }
    
    public class CustomField {
        public String name;
        public String uniqueCode;
        public String value;
        public String definitionId;
        
    }
    
    public class CustomFieldSearchFilterInput {
        public String id;
        public String names;
        public String uniqueCodes;
        
    }
    
    public class EventMarketingRecord{
         public String name;
         public String value;
         public tag tag;
         public String id;
    }
    public class tag{
        public String id;
        public String name;
    }
    public class Event {
        public String id;
         public String name;
        public String startDate;
        public String endDate;  
        Datetime createdAt;
        public List<Contact> contacts;
        public venue venue;
        public logo logo;
        //public List<Registration> registrations;
        //public List<FunctionRegistration> functionRegistrations;
        
    }
    
    public class venue {
        public String city;
        public String country;
        public String name;
        public String state;
         
    }
    
     public class logo {
        public string url;
   }
    
    public class Function {
        public String id;
        public String name;
        public String start;
        public String functionend;
        public String functiondate;
        public String overview;
        public String details;
    }
    
    public class Fee {
        decimal amount;        
    }
    
    public class FunctionFeeType {
        public String id;
        public String name;
        public String uniqueCode;
        public List<Fee> fees;
    }
    
    public class FunctionRegistration {
        public String id;        
        public String tickets;
        public Contact contact;
        public Function function;
        public Datetime checkInDate;
        public Datetime checkOutDate;
        public RegistrationPaymentDetails paymentDetails;
        public FunctionFeeType feeType;
    }
    
    public class RegistrationPaymentDetails {
        public String paymentStatus;
        public RegistrationDiscountCode discountCode;
        public decimal discountAmount;
        public decimal adjustmentAmount;
        public decimal taxAmount;
        public decimal totalChargeAmount;
    }
    
    public class FunctionRegistrationPaymentDetails  {
        public String paymentStatus;
        public FunctionDiscountCode discountCode;
        public decimal discountAmount;
        public decimal adjustmentAmount;
        public decimal taxAmount;
        public decimal totalChargeAmount;
    }
    
  /*  public enum PaymentStatus {
        // Define the possible payment status values here
    } */
    
    public class RegistrationDiscountCode {
        public String code;
    }
     public class FunctionDiscountCode {
        public String code;
    }

    
    public class RegistrationType {
        public String id;
        public String name;
        public String uniqueCode;
        public List<Fee> fees;
    }
    
    public class Registration {
        public String id;
        public Datetime registrationDateTime;
        public Contact contact;
        public RegistrationPaymentDetails paymentDetails;
        public RegistrationType type;
    }
    
    public class paymentDetails {
        public String paymentStatus;
        public decimal totalChargeAmount;
        public decimal taxAmount;
        public decimal adjustmentAmount;
     }
    
    public class Data {
        public Event event;
    }
    
    public Data data;
}