<%
    ui.decorateWith("appui", "standardEmrPage", [title: "Add Account Drug"])
    ui.includeCss("pharmacyapp", "container.css")
    ui.includeCss("ehrconfigs", "referenceapplication.css")

    ui.includeJavascript("ehrinventoryapp", "jq.print.js")
    ui.includeJavascript("ehrconfigs", "emr.js")
    ui.includeJavascript("ehrconfigs", "knockout-2.2.1.js")
    ui.includeJavascript("ehrconfigs", "jquery.simplemodal.1.4.4.min.js")

%>
<script>
    var processCounts = 0;

    jq(function () {
        var accountName;
        var accountObject;
        var selectedDrugId;
        var isAccountCreated = false;
        jq("#issueDrugSelection").hide();
        jq("#issueDetails").hide();

        jq("#addIssueButton").on("click", function (e) {
            jq('#issueDrugCategory').val(0).change();
            jq('#issueSearchPhrase').val('');
            jq('#issueDetails').hide();
            addissuedialog.show();
        });

        var addissuedialog = emr.setupConfirmationDialog({
			dialogOpts: {
				overlayClose: false,
				close: true
			},
            selector: '#addIssueDialog',
            actions: {
                confirm: function () {
                    issueList.addDrugItem();

                    if (processCounts === 0) {
                        jq().toastmessage('showErrorToast', "Ensure information has been properly filled.");
                        return false;
                    }

                    jq("#issueDrugSelection").hide();
                    jq("#issueDrugKey").show();

                    addissuedialog.close();
                },
                cancel: function () {


                    jq("#issueDrugSelection").hide();
                    jq("#issueDrugKey").show();
                    addissuedialog.close();
                }
            }
        });

        jq("#issueSearchPhrase").autocomplete({
            minLength: 3,
            source: function (request, response) {
                jq.getJSON('${ ui.actionLink("pharmacyapp", "addReceiptsToStore", "fetchDrugListByName") }',
                        {
                            searchPhrase: request.term
                        }
                ).success(function (data) {
                            var results = [];
                            for (var i in data) {
                                var result = {label: data[i].name, value: data[i]};
                                results.push(result);
                            }
                            response(results);
                        });
            },
            focus: function (event, ui) {
                jq("#issueSearchPhrase").val(ui.item.value.name);
                return false;
            },
            select: function (event, ui) {
                event.preventDefault();
                selectDrug = ui.item.value.name;
                selectedDrugId = ui.item.value.id
                jQuery("#issueSearchPhrase").val(selectDrug);

                //set parent category
                var catId = ui.item.value.category.id;
                jq("#issueDrugCategory").val(catId);

                var drugName = selectDrug;
                var drugFormulationData = "";
                jq('#issueDrugFormulation').empty();

                if (drugName === "") {
                    jq('<option value="">Select Formulation</option>').appendTo("#issueDrugFormulation");
                } else {
                    jq.getJSON('${ ui.actionLink("pharmacyapp", "addReceiptsToStore", "getFormulationByDrugName") }', {
                        drugName: drugName
                    }).success(function (data) {
                        drugFormulationData = drugFormulationData + '<option value="">Select Formulation</option>';
                        for (var key in data) {
                            if (data.hasOwnProperty(key)) {
                                var val = data[key];
                                for (var i in val) {
                                    var name, dozage;
                                    if (val.hasOwnProperty(i)) {
                                        var j = val[i];
                                        if (i == "id") {
                                            drugFormulationData = drugFormulationData + '<option id="' + j + '">';
                                        } else if (i == "name") {
                                            name = j;
                                        }
                                        else {
                                            dozage = j;
                                            drugFormulationData = drugFormulationData + (name + "-" + dozage) + '</option>';
                                        }
                                    }
                                }
                            }

                        }

                        jq(drugFormulationData).appendTo("#issueDrugFormulation");
                    }).error(function (xhr, status, err) {
                        jq('<option value="">Select Formulation</option>').appendTo("#issueDrugFormulation");
                        jq().toastmessage('showErrorToast', "AJAX error!" + err);
                    });
                }


            }
        });

        jq("#issueDrugCategory").on("change", function (e) {
            var categoryId = jq(this).children(":selected").attr("value");
            var drugNameData = "";
            jq('#issueDrugName').empty();

            if (categoryId === "0") {
                jq('<option value="">Select Drug</option>').appendTo("#issueDrugName");
                jq('#issueDrugName').change();

            } else {
                jq.getJSON('${ ui.actionLink("pharmacyapp", "addReceiptsToStore", "fetchDrugNames") }', {
                    categoryId: categoryId
                }).success(function (data) {
                    drugNameData = drugNameData + '<option value="">Select Drug Name</option>';                    
                    jQuery("#issueDrugKey").hide();
                    jQuery("#issueDrugSelection").show();
                    for (var key in data) {
                        if (data.hasOwnProperty(key)) {
                            var val = data[key];
                            for (var i in val) {
                                if (val.hasOwnProperty(i)) {
                                    var j = val[i];
                                    if (i == "id") {
                                        drugNameData = drugNameData + '<option id="' + j + '"' + ' value="' + j + '"';
                                    }
                                    else {
                                        drugNameData = drugNameData + 'name="' + j + '">' + j + '</option>';
                                    }
                                }
                            }
                        }
                    }

                    jq(drugNameData).appendTo("#issueDrugName");
                    jq('#issueDrugName').change();
                }).error(function (xhr, status, err) {
                    jq('<option value="">Select Drug Name</option>').appendTo("#issueDrugName");                    
                    jq().toastmessage('showErrorToast', "AJAX error!" + err);
                });
            }

        });

        jq("#issueDrugName").on("change", function (e) {
            var drugName = jq(this).children(":selected").attr("name");
            var drugId = jq(this).children(":selected").attr("id");

            selectedDrugId = drugId;

            var drugFormulationData = "";
            jq('#issueDrugFormulation').empty().change();

            if (jq(this).children(":selected").attr("value") === "") {
                jq('<option value="">Select Formulation</option>').appendTo("#issueDrugFormulation");
            } else {
                jq.getJSON('${ ui.actionLink("pharmacyapp", "addReceiptsToStore", "getFormulationByDrugName") }', {
                    drugName: drugName
                }).success(function (data) {
                    drugFormulationData = drugFormulationData + '<option value="">Select Formulation</option>';
                    for (var key in data) {
                        if (data.hasOwnProperty(key)) {
                            var val = data[key];
                            for (var i in val) {
                                var name, dozage;
                                if (val.hasOwnProperty(i)) {
                                    var j = val[i];
                                    if (i === "id") {
                                        drugFormulationData = drugFormulationData + '<option id="' + j + '">';
                                    } else if (i === "name") {
                                        name = j;
                                    }
                                    else {
                                        dozage = j;
                                        drugFormulationData = drugFormulationData + (name + "-" + dozage) + '</option>';
                                    }
                                }
                            }
                        }
                    }
                    jq(drugFormulationData).appendTo("#issueDrugFormulation");
                }).error(function (xhr, status, err) {
                    jq().toastmessage('showErrorToast', "AJAX error!" + err);
                });
            }

        });

        jq("#issueDrugFormulation").on("change", function (e) {
            var formulationId = jQuery(this).children(":selected").attr("id");
            var drugId = selectedDrugId;
            jQuery.ajax({
                type: "GET"
                , dataType: "json"
                , url: '${ ui.actionLink("pharmacyapp", "issueDrugAccountList", "listReceiptDrug") }'
                , data: ({drugId: drugId, formulationId: formulationId})
                , async: false
                , success: function (response) {
                    issueList.listReceiptDrug.removeAll();
                    jq.map(response, function (val, i) {
                        issueList.addDrugToFormulationList(val, 0);
                    });
					
                    if (issueList.listReceiptDrug().length === 0) {
                        jq("#issueDetails").show();
                    } else {
                        jq("#issueDetails").hide();
                    }
					
					addissuedialog.close();
					addissuedialog.show();
                },
                error: function (xhr) {
                    alert("An Error occurred");
                }
            })
        });

        function IssueViewModel() {
            var self = this;
//            Non Editable Catalogue - Comes from the server
            self.drugList = ko.observableArray([]);

//            Editable Data
            self.selectedDrugs = ko.observableArray([]);

//            List of Drugs By Formulation
            self.listReceiptDrug = ko.observableArray([]);

//            Observable account object
            self.listAccount = ko.observable();


//            Operations
            self.addDrugToList = function (item, quantity) {
                self.selectedDrugs.push(new DrugIssue(item, quantity));
            };
            self.addDrugToFormulationList = function (item, quantity) {
                self.listReceiptDrug.push(new DrugIssue(item, quantity));
            };

            self.removeDrugFromList = function (drug) {
                self.selectedDrugs.remove(drug);
            };

            self.addDrugItem = function () {
                processCounts = 0;

                jq.map(self.listReceiptDrug(), function (val, i) {
                    if (val.quantity() > 0) {
                        self.addDrugToList(val.item(), val.quantity());
                        processCounts++;
                    }
                });
            };

            self.clearList = function () {
                if (self.selectedDrugs().length > 0) {
                    self.selectedDrugs.removeAll();
                    isAccountCreated = false;
                } else {
                    jq().toastmessage('showErrorToast', "No Drugs in Issue List!");
                }
                isAccountCreated = false;

            };

            self.returnToList = function () {
                window.location.href = ui.pageLink("pharmacyapp", "container", {
                    "rel": "issue-to-account"
                });
            };

            self.processIssueDrugToAccount = function () {				
				if (self.selectedDrugs().length === 0){
					jq().toastmessage('showErrorToast', "No Drugs added to the List!");
					return false;
				}
				
				jq("#accountName").val('');
				addaccountforissueslipdialog.show();
            };
        }

        function DrugIssue(item, quantity) {
            var self = this;
            self.item = ko.observable(item);
            self.quantity = ko.observable(quantity);
            self.quantity.subscribe(function (newValue) {
                if (newValue > self.item().currentQuantity) {
                    jq().toastmessage('showErrorToast', "Issue quantity is greater that available quantity!");
                    self.quantity(0);
                }
            });
        }

        var addaccountforissueslipdialog = emr.setupConfirmationDialog({
			dialogOpts: {
				overlayClose: false,
				close: true
			},
            selector: '#addAccountForIssueSlip',
            actions: {
                confirm: function () {
                    if (jq("#accountName").val().trim() === '') {
                        jq().toastmessage('showErrorToast', "Enter Account Name!");
                    } else {
						jq().toastmessage({
							sticky: true
						});
						var savingMessage = jq().toastmessage('showSuccessToast', 'Please wait as Information is being Saved...');
					
						var drugsJson 	= ko.toJSON(issueList.selectedDrugs());
						var accountName = jq("#accountName").val().trim().toUpperCase();
						
						issueList.listAccount(accountName);
						
						var addIssueDrugsData = {
							'selectedDrugs': drugsJson,
							'accountName': accountName
						};
						
						jq.getJSON('${ ui.actionLink("pharmacyapp", "issueDrugAccountList", "processIssueDrugAccount") }', addIssueDrugsData)
						.success(function (data) {
							jq().toastmessage('removeToast', savingMessage);
							jq().toastmessage('showSuccessToast', "Save Order Successful!");
							
							jq("#print-section").print({
								globalStyles: 	false,
								mediaPrint: 	false,
								stylesheet: 	'${ui.resourceLink("ehrinventoryapp", "styles/print-out.css")}',
								iframe: 		false,
								width: 			980,
								height:			700
							});
							
							var emrLink = ui.pageLink("ehrinventoryapp", "main");
							window.location.href = emrLink.substring(0, emrLink.length-1)+'#accounts'

						})
						.error(function (xhr, status, err) {
							jq().toastmessage('removeToast', savingMessage);
							jq().toastmessage('showErrorToast', "AJAX error!" + err);
						});
                    
                        addaccountforissueslipdialog.close();
                    }
                },
                cancel: function () {
                    addaccountforissueslipdialog.close();
                }
            }
        });

        var issueList = new IssueViewModel();
        ko.applyBindings(issueList, jq("#accountDrugIssue")[0]);
    });//end of doc ready
</script>

<style>
	th:first-child {
		width: 5px;
	}

	th:last-child {
		width: 30px;
	}

	th:nth-child(5) {
		width: 85px;
	}

	#dialog-table th:nth-child(6) {
		width: 90px;
	}

	#dialog-table th:nth-child(2),
	#dialog-table th:nth-child(3) {
		width: 55px;
	}

	.dialog-content label {
		display: inline-block;
		width: 120px;
	}

	.dialog .dialog-content li {
		margin-bottom: 0px;
	}

	.dialog label {
		display: inline-block;
		width: 115px;
	}

	.dialog select option {
		font-size: 1.0em;
	}

	.dialog select {
		display: inline-block;
		margin: 4px 0 0;
		width: 470px;
		height: 38px;
	}

	.dialog input {
		display: inline-block;
		width: 448px;
		min-width: 10%;
		margin: 4px 0 0;
	}

	.dialog td input {
		width: 40px;
	}

	.dialog textarea {
		display: inline-block;
		width: 248px;
		min-width: 10%;
		resize: none
	}

	form input:focus, form select:focus, form textarea:focus, form ul.select:focus, .form input:focus, .form select:focus, .form textarea:focus, .form ul.select:focus {
		outline: 1px none #007fff;
	}
	.print-only{
		display: none;
	}
	#modal-overlay {
		background: #000 none repeat scroll 0 0;
		opacity: 0.4 !important;
	}
</style>

<div class="clear"></div>

<div id="accounts-div">
    <div class="container">
        <div class="example">
            <ul id="breadcrumbs">
                <li>
                    <a href="${ui.pageLink('kenyaemr', 'userHome')}">
                        <i class="icon-home small"></i></a>
                </li>

                <li>
                    <a href="${ui.pageLink('ehrinventoryapp', 'main')}">
                        <i class="icon-chevron-right link"></i>
                        Inventory
                    </a>
                </li>

                <li>
                    <a href="${ui.pageLink('ehrinventoryapp', 'main')}#accounts">
                        <i class="icon-chevron-right link"></i>
                        Issue to Account
                    </a>
                </li>

                <li>
                    <i class="icon-chevron-right link"></i>
                    Add Drugs
                </li>
            </ul>
        </div>

        <div class="patient-header new-patient-header">
            <div class="demographics">
                <h1 class="name" style="border-bottom: 1px solid #ddd;">
                    <span>&nbsp; ISSUE DRUGS TO ACCOUNT &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</span>
                </h1>
            </div>

            <div class="show-icon">
                &nbsp;
            </div>

            <span class="button confirm right" name="addIssueButton" id="addIssueButton" style="margin-top:15px;">
                <i class="icon-plus-sign small"></i>
                Add To Slip
            </span>
        </div>
    </div>
</div>

<div id="accountDrugIssue">
	<div id="print-section">
		<div class="print-only">
			<center>
				<img width="100" height="100" align="center" title="Integrated KenyaEMR" alt="Integrated KenyaEMR" src="${ui.resourceLink('ehrinventoryapp', 'images/kenya_logo.bmp')}">
				<h2>${userLocation}</h2>
				<h2>ISSUE DRUGS TO ACCOUNT</h2>
			</center>
			
			<div>
				<label>
					Account Name:
				</label>
				<span data-bind="text: listAccount() ? listAccount() : 'UNKNOWN'"></span>
				<br/>
				
				<label>
					Print Date:
				</label>
				<span>${date}</span>
				<br/>		
			</div>
		</div>
		
		<table id="addDrugsAccount">
			<thead>
			<tr role="row">
				<th>#</th>
				<th>CATEGORY</th>
				<th>DRUG NAME</th>
				<th>FORMULATION</th>
				<th>QUANTITY</th>
				<th>&nbsp;</th>
			</tr>
			</thead>

			<tbody data-bind="foreach: selectedDrugs">
			<tr>
				<td data-bind="text: \$index() + 1"></td>
				<td data-bind="text: item().drug.category.name"></td>
				<td data-bind="text: item().drug.name"></td>
				<td>
					<span data-bind="text: item().formulation.name"></span>-
					<span data-bind="text: item().formulation.dozage"></span>
				</td>
				<td data-bind="text: quantity"></td>
				<td>
					<a class="remover" href="#" data-bind="click: \$root.removeDrugFromList">
						<i class="icon-remove small" style="color:red"></i>
					</a>
				</td>
			</tr>
			</tbody>
		</table>
		
		<div class="print-only" style="padding-top: 30px">
			<span>Signature of inventory clerk / Stamp</span>
		</div>
	</div>

    <input type="button" value="Back To List" class="button cancel" name="returnToDrugList"
           id="returnToDrugList" style="margin-top:5px;" data-bind="click: \$root.returnToList">

    <span class="button confirm right" name="addDrugsSubmitButton" id="addDrugsSubmitButton"
          style="margin: 5px 0px 0px;"
          data-bind="click: \$root.processIssueDrugToAccount">
        <i class="icon-save small"></i>
        Save & Print
    </span>

    <div id="addIssueDialog" class="dialog" style="display: none; width: 900px">
        <div class="dialog-header">
            <i class="icon-folder-open"></i>

            <h3>Drug Information</h3>
        </div>

        <form id="issueDialogForm">
            <div class="dialog-content">
                <ul>
                    <li>
                        <label for="issueDrugCategory">Drug Category</label>
                        <select name="issueDrugCategory" id="issueDrugCategory">
                            <option value="0">Select Category</option>
                            <% if (listCategory != null || listCategory != "") { %>
                            <% listCategory.each { drugCategory -> %>
                            <option id="${drugCategory.id}" value="${drugCategory.id}">${drugCategory.name}</option>
                            <% } %>
                            <% } %>
                        </select>
                    </li>
                    <li>
                        <div id="issueDrugKey">
                            <label for="issueSearchPhrase">Drug Name</label>
                            <input id="issueSearchPhrase" name="issueSearchPhrase"/>
                        </div>
                        <div id="issueDrugSelection">
                            <label for="issueDrugName">Drug Name</label>
                            <select name="issueDrugName" id="issueDrugName">
                                <option value="0">Select Drug Name</option>
                            
                            </select>
                        </div>
                    </li>
                    <li>
                        <label for="issueDrugFormulation">Formulation</label>
                        <select name="issueDrugFormulation" id="issueDrugFormulation">
                            <option value="0">Select Formulation</option>
                        </select>
                    </li>

                    <div id="issueDetails" style="color: red;">
                    This Drug is empty in your store please order it!
                    </div>

                    <div id="issueDetailsList" data-bind="visible: \$root.listReceiptDrug().length > 0">
                        <form method="post" id="processDrugOrderForm" class="box">
                            <table id="dialog-table">
                                <thead>
                                <tr>
                                    <th>#</th>
                                    <th>EXPIRY</th>
                                    <th title="Date of manufacturing">DM</th>
                                    <th>COMPANY</th>
                                    <th>BATCH#</th>
                                    <th title="Quantity available">AVAILABLE</th>
                                    <th title="Issue quantity">ISSUE</th>
                                </tr>
                                </thead>
                                <tbody data-bind="foreach: listReceiptDrug">
                                <tr>
                                    <td data-bind="text: \$index() + 1"></td>
                                    <td data-bind="text: (item().dateExpiry).substring(0,11)"></td>
                                    <td data-bind="text: item().dateManufacture"></td>
                                    <td data-bind="text: item().companyNameShort"></td>
                                    <td data-bind="text: item().batchNo"></td>
                                    <td data-bind="text: item().currentQuantity"></td>
                                    <td><input class="input-quantity" data-bind="value: quantity"></td>
                                </tr>
                                </tbody>
                            </table>
                            <br/>
                        </form>
                    </div>
                    <span class="button confirm right" id="drugIssue">Add Drug</span>
                    <span class="button cancel">Cancel</span>
                </ul>
            </div>

            <div id="addAccountForIssueSlip" class="dialog">
                <div class="dialog-header">
                    <i class="icon-folder-open"></i>

                    <h3>Add Account For Slip</h3>
                </div>

                <div class="dialog-content">
                    <ul>
                        <li>
                            <form id="createAccountForm">
                                <label for="accountName">Name</label>
                                <input type="text" name="accountName" id="accountName" style="width: 100%"/>
                            </form>
                        </li>
                    </ul>

                    <span class="button confirm right">Confirm</span>
                    <span class="button cancel">Cancel</span>
                </div>
            </div>
        </form>
    </div>


</div>
