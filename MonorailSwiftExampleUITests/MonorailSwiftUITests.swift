import XCTest

class MonorailSwiftUITests: UITestBase {
    
    func testLoadAllQuestion() {
        
        Robot(name: "HomePage", app).with {
            $0.iSee(.naviBarButton("Login"))
            $0.iSee(.naviBarButton("Refresh"))
            
            if isMockTest {
                $0.iSee(.tableCell("cell_0_1"), has: "Applying multiple CIFilters on image")
            }
            
            $0.iTap(.tableCell("cell_0_1"))
            sleep(1)
            
            $0.iSee(.label("qTitle"))
            $0.iSee(.label("qBody"))
            $0.iSeeNo(.button("qFavorite"))
            
            if isMockTest {
                $0.iSee(.label("qTitle"), has: "Applying multiple CIFilters on image")
            }
            
            $0.iTap(.naviBarButton("StackOverflow"))
            $0.iSee(.tableCell("cell_0_1"))
        }
        
    }
    
}
