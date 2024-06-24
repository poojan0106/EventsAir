public class ExpocadWrapper {

    public Boolean success;
    public String message;
    
    // Constructor to set response values
    public ExpocadWrapper(Boolean success, String message /* Other response attributes */) {
        this.success = success;
        this.message = message;
        // Set other response attributes
    }
    

	public class PavilionNames {
        public String Name { get; set; }
    }    
    
    public class BoothInfo {
        public String ExhibitorId { get; set; }
        public String BoothNumber { get; set; }
        public String Dimensions { get; set; }
        public String DisplayNameOverride { get; set; }
        public String XSize { get; set; }
        public String YSize { get; set; }
        public String Area { get; set; }
        public Decimal NumericArea { get; set; }
        // public Object CalculatedArea { get; set; }
        // public Object ObstructionsArea { get; set; }
        public String Status { get; set; }
        public List<String> BoothClasses { get; set; }
        public List<String> ChildExhibitors { get; set; }
        public String Pavilion { get; set; }
        public String ShowInShow { get; set; }
        public String BoothType { get; set; }
        public String UnitType { get; set; }
        public String HoldExhibitorId { get; set; }
        public String HoldExhibitorName { get; set; }
        public String HoldComment { get; set; }
        public Integer OpenCorners { get; set; }
        public Boolean IsDeleted { get; set; }
        public Boolean IsOnHold { get; set; }
        public Boolean IsRented { get; set; }
    }
    
    public class Exhibitor {
        public String Address1 { get; set; }
        public String Address2 { get; set; }
        public String City { get; set; }
        public String Comments { get; set; }
        public String Comments2 { get; set; }
        public String Contact { get; set; }
        public String Country { get; set; }
        public String CellPhone { get; set; }
        public String DisplayOnDrawing { get; set; }
        public String DoingBusinessAs { get; set; }
        public String DoingBusinessAsDisplayOnDrawing { get; set; }
        public String Email { get; set; }
        public String ExhibitorId { get; set; }
        public String ExhibitorName { get; set; }
        public String ExhibitorNameLine2 { get; set; }
        public String Fax { get; set; }
        public String Field1 { get; set; }
        public String Field2 { get; set; }
        public String Field3 { get; set; }
        public String Field4 { get; set; }
        public String Field5 { get; set; }
        public String Field6 { get; set; }
        public String Field7 { get; set; }
        public String Field8 { get; set; }
        public String Field9 { get; set; }
        public String NickName { get; set; }
        public String Salutation { get; set; }
        public String Title { get; set; }
        public String Phone { get; set; }
        public String PostalCode { get; set; }
        public String PrimaryGroup { get; set; }
        public String PriorityPoints { get; set; }
        public String ProductDescription { get; set; }
        public String State { get; set; }
        public String WebSite { get; set; }
        public Integer Member { get; set; }
    }
    
    public class SpecificBoothInfo {
        public String Color { get; set; }
        public String Flyout { get; set; }
        public String MArea { get; set; }
        public String MSize { get; set; }
        public Integer NumberExhibitorText { get; set; }
        public Integer NumCorners { get; set; }
        public Integer NumOpenCorners { get; set; }
        public Integer Nx { get; set; }
        public Integer Ny { get; set; }
        public Integer Rotation { get; set; }
        public String Size { get; set; }
        public Integer TextSize { get; set; }
        public List<Corner> Corners { get; set; }
        public List<ExhibitorText> ExhibitorTexts { get; set; }
        public String Area { get; set; }
        public String BoothNumber { get; set; }
        public String ExhibitorId { get; set; }
        public String Pavilion { get; set; }
        public String ShowInShow { get; set; }
        public String Type { get; set; }
        public String Status { get; set; }
        public Boolean IsDeleted { get; set; }
        public Boolean IsOnHold { get; set; }
        public Boolean IsRented { get; set; }
        public List<Cost> Cost { get; set; }
    }
    
    public class Corner {
        public Integer X { get; set; }
        public Integer Y { get; set; }
    }
    
    public class ExhibitorText {
        public Integer Nx { get; set; }
        public Integer Ny { get; set; }
        public Integer Rotation { get; set; }
        public String Text { get; set; }
        public Integer TextSize { get; set; }
        public Integer isDimension { get; set; }
    }
    
    public class Cost {
        public String planName { get; set; }
        public Decimal cost { get; set; }
    }
}