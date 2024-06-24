@isTest
public class ExpocadWrapperTest {
    @isTest
    static void testExpocadWrapperConstructor() {
        // Test constructor with success value true and a message
        ExpocadWrapper wrapper1 = new ExpocadWrapper(true, 'Success message');
        System.assertEquals(true, wrapper1.success);
        System.assertEquals('Success message', wrapper1.message);

        // Test constructor with success value false and a message
        ExpocadWrapper wrapper2 = new ExpocadWrapper(false, 'Error message');
        System.assertEquals(false, wrapper2.success);
        System.assertEquals('Error message', wrapper2.message);

        // Add more test cases as needed to cover other scenarios
        Test.startTest();
        ExpocadWrapper.PavilionNames pavilion = new ExpocadWrapper.PavilionNames();
        pavilion.Name = 'Test Pavilion';

        ExpocadWrapper.BoothInfo BoothInfo = new ExpocadWrapper.BoothInfo();
        BoothInfo.ExhibitorId = '001AD00000CtCzKYAVNg';
        BoothInfo.BoothNumber = 'A1';
        BoothInfo.Dimensions = '11m x 12m';
        BoothInfo.DisplayNameOverride = '';
        BoothInfo.XSize = '11m';
        BoothInfo.YSize = '12m';
        BoothInfo.Area = '132 m²';
        BoothInfo.Status = 'Initial';
        // BoothInfo.BoothClasses = [];
        // BoothInfo.ChildExhibitors = [];
        BoothInfo.Pavilion = '';
        BoothInfo.ShowInShow = '';
        BoothInfo.BoothType = 'Island';
        BoothInfo.UnitType = 'm';
        BoothInfo.HoldExhibitorId = '';
        BoothInfo.HoldExhibitorName = '';
        BoothInfo.HoldComment = '';
        BoothInfo.OpenCorners = 4;
        BoothInfo.IsDeleted = false;
        BoothInfo.IsOnHold = false;
        BoothInfo.IsRented = true;

        ExpocadWrapper.Corner Corner = new ExpocadWrapper.Corner();
        Corner.X=10;
        Corner.Y=12;

        ExpocadWrapper.Cost CostWrap = new ExpocadWrapper.Cost();
        CostWrap.planName='test';
        CostWrap.cost=12.3;

        ExpocadWrapper.ExhibitorText ExhibitorText = new ExpocadWrapper.ExhibitorText();
        ExhibitorText.Nx=2;
        ExhibitorText.Ny=12;
        ExhibitorText.Rotation=12;
        ExhibitorText.Text='Tes';
        ExhibitorText.TextSize=3;
        ExhibitorText.isDimension=12;


        ExpocadWrapper.Exhibitor Exhibitor = new ExpocadWrapper.Exhibitor();
        Exhibitor.Address1='Test';
        Exhibitor.Address2='Test';
        Exhibitor.City='Test';
        Exhibitor.Contact='Test';
        Exhibitor.Country='Test';
        Exhibitor.CellPhone='Test';
        Exhibitor.DisplayOnDrawing='Test';
        Exhibitor.DoingBusinessAs='Test';
        Exhibitor.DoingBusinessAsDisplayOnDrawing='Test';
        Exhibitor.Email='Test';
        Exhibitor.ExhibitorId='Test';
        Exhibitor.ExhibitorName='Test';
        Exhibitor.ExhibitorNameLine2='Test';
        Exhibitor.Fax='Test';
        Exhibitor.Field1='Test';
        Exhibitor.Field2='Test';
        Exhibitor.Field3='Test';
        Exhibitor.Field4='Test';
        Exhibitor.Field5='Test';
        Exhibitor.Field6='Test';
        Exhibitor.Field7='Test';
        Exhibitor.Field8='Test';
        Exhibitor.Field9='Test';
        Exhibitor.NickName='Test';
        Exhibitor.Salutation='Test';
        Exhibitor.Title='Test';
        Exhibitor.Phone='Test';
        Exhibitor.PostalCode='Test';
        Exhibitor.PrimaryGroup='Test';
        Exhibitor.PriorityPoints='Test';
        Exhibitor.ProductDescription='Test';
        Exhibitor.State='Test';
        Exhibitor.WebSite='Test';
        Exhibitor.Member=10;



        ExpocadWrapper.SpecificBoothInfo SpecificBoothInfo = new ExpocadWrapper.SpecificBoothInfo();
        SpecificBoothInfo.Color='Test';
        SpecificBoothInfo.Flyout='Test';
        SpecificBoothInfo.MArea='Test';
        SpecificBoothInfo.MSize='Test';
        SpecificBoothInfo.NumberExhibitorText=2;
        SpecificBoothInfo.NumCorners=3;
        SpecificBoothInfo.NumOpenCorners=4;
        SpecificBoothInfo.Nx=6;
        SpecificBoothInfo.Ny=6;
        SpecificBoothInfo.Rotation=3;
        SpecificBoothInfo.Size='23';
        SpecificBoothInfo.TextSize=4;
        SpecificBoothInfo.Area='34 m2';
        SpecificBoothInfo.BoothNumber='A17';
        SpecificBoothInfo.ExhibitorId='Test';
        SpecificBoothInfo.Pavilion='';
        SpecificBoothInfo.ShowInShow='Test';
        SpecificBoothInfo.Type='Test';
        SpecificBoothInfo.Status='Test';
        SpecificBoothInfo.IsDeleted=false;
        SpecificBoothInfo.IsOnHold=true;
        SpecificBoothInfo.IsRented=false;
       

       
        Test.stopTest();
    }
}