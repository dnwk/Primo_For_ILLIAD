-- About ExLibris_Alma_Primo.lua
--
-- Author:  Bill Jones III, SUNY Geneseo, IDS Project, jonesw@geneseo.edu
-- ExLibris_Alma_Primo.lua does an ISxN or Title search for loans and articles on a Library's ALMA / Primo instance.
-- This Addon may be set to default search on either ISxN or Title setting the value "StartwithISxN" to TRUE in the Addon Configuration under Manage Addons
-- autoSearch (boolean) determines whether the search is performed automatically when a request is opened or not.
-- For your own library catalog, go to the 'Basic Search' page and copy the short version of the URL to enter in for the value of "libraryurl" in the Addon Configuration under Manage Addons
-- You are able to name the Addon Tab!  In the the Addon Configuration under Manage Addons, change the "AddonRibbonName" value to reflect your catalog (example: Primo) (example: Alma)
-- set autoSearch to true for this script to automatically run the search when the request is opened.
-- 
-- IMPORTING CALL NUMBER AND LOCATION INFORMATION INTO THE DETAILS TAB:
-- In order to input the Call Number and Location information into the request, click on the "Locations" tab of the requested item within the catalog.
-- Once the Call Number and Location information has populated on the page, click on the "Input Location/Call Number" button on the top ILLiad Client ribbon.
-- You will automatically be redirected to the Details tab.
-- Be sure to click Save for the item in the "Details" tab of the request.




local settings = {};
settings.localurl = GetSetting("localurl");
settings.autoSearch = GetSetting("AutoSearch");
settings.Popup = GetSetting("Popup");
settings.AddonRibbonName = GetSetting("AddonRibbonName");
local interfaceMngr = nil;
local ExLibrisForm = {};
local libraryurl = settings.localurl
ExLibrisForm.Form = nil;
ExLibrisForm.Browser = nil;
ExLibrisForm.RibbonPage = nil;



function Init()

		--if GetFieldValue("Transaction", "RequestType") == "Loan" then
			interfaceMngr = GetInterfaceManager();
			
			-- Create browser
			ExLibrisForm.Form = interfaceMngr:CreateForm(settings.AddonRibbonName, "Script");
			ExLibrisForm.Browser = ExLibrisForm.Form:CreateBrowser("ExLibris", "ExLibris", "ExLibris");
			
			-- Hide the text label
			ExLibrisForm.Browser.TextVisible = false;
			
			--Suppress Javascript errors
			ExLibrisForm.Browser.WebBrowser.ScriptErrorsSuppressed = true;
			
			-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
			ExLibrisForm.RibbonPage = ExLibrisForm.Form:GetRibbonPage("ExLibris");
		    ExLibrisForm.RibbonPage:CreateButton("Search ISxN", GetClientImage("Search32"), "SearchISxN", settings.AddonRibbonName);
			ExLibrisForm.RibbonPage:CreateButton("Search Title", GetClientImage("Search32"), "SearchTitle", settings.AddonRibbonName);
			ExLibrisForm.RibbonPage:CreateButton("Input Location/ Call Number", GetClientImage("Borrowing32"), "InputLocation", "Location Info");
			
			ExLibrisForm.Form:Show();
            
			if settings.autoSearch then
			    if settings.StartwithISxN and GetFieldValue("Transaction", "ISSN") ~= "" then
				   ExLibrisForm.Browser:RegisterPageHandler("formExists", "searchForm", "SearchISxN", false);
			    else
                   ExLibrisForm.Browser:RegisterPageHandler("formExists", "searchForm", "SearchTitle", false);
				end
				ExLibrisForm.Browser:Navigate(libraryurl);
			end
			 		          
end



function SearchISxN()
    if GetFieldValue("Transaction", "ISSN") ~= "" then
		ExLibrisForm.Browser:SetFormValue("searchForm","search_field",GetFieldValue("Transaction", "ISSN"));
	else
       interfaceMngr:ShowMessage("ISxN is not available from request form", "Insufficient Information");
	end
       ExLibrisForm.Browser:ClickObject("goButton")
	end

function SearchTitle()
	local Articletitle = nil;
	local Loantitle = nil;
    if GetFieldValue("Transaction", "RequestType") == "Loan" then  
		if string.find(GetFieldValue ("Transaction", "LoanTitle"),"/",1) ~=nil then
			Loantitle = string.sub(GetFieldValue ("Transaction", "LoanTitle"),1, string.find(GetFieldValue ("Transaction", "LoanTitle"),"/",1)-1);
		else
			Loantitle = GetFieldValue ("Transaction", "LoanTitle");
		end
		
		ExLibrisForm.Browser:SetFormValue("searchForm","search_field", Loantitle);
	else
		if string.find(GetFieldValue ("Transaction", "PhotoArticleTitle"),"/",1)~=nil then
			 Articletitle = string.sub(GetFieldValue ("Transaction", "PhotoArticleTitle"),1, string.find(GetFieldValue ("Transaction", "PhotoArticleTitle"),"/",1)-1);
		else
			 Articletitle = GetFieldValue ("Transaction", "PhotoJournalTitle");
		end
		
		ExLibrisForm.Browser:SetFormValue("searchForm","search_field", Articletitle);
	end
	   ExLibrisForm.Browser:ClickObject("goButton")
end


function InputLocation()
		local element =nil;
		local cElements = ExLibrisForm.Browser.WebBrowser.Document:GetElementsByTagName("span");
			if cElements == nil then
				return false;
			end
				
			for i=0, cElements.Count - 1 do
				
				local element1 = ExLibrisForm.Browser:GetElementByCollectionIndex(cElements, i);
					if element1:GetAttribute("className")=="EXLAvailabilityCollectionName" then
			            SetFieldValue("Transaction", "Location", element1.InnerText);
					end
				
					if element1:GetAttribute("className")=="EXLAvailabilityCallNumber" then
			            SetFieldValue("Transaction", "CallNumber", element1.InnerText);
						break
					end
			end
	ExecuteCommand("SwitchTab", {"Detail"});
end