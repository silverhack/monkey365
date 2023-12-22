var IssuesByServiceChartOptions = {
	responsive: true,
	legend: false,
	scales: {
		x: {
			  stacked: true,
		  },
		y: {
			  stacked: true,
		  }
	}
};

var IssuesBySeverityChartOptions = {
	responsive: true,
	animation: {
	  animateScale: true,
	  animateRotate: true
	},
	plugins: {
		legend: {
			position: 'bottom',
			title: {
			  display: true,
			  padding: 15,
			},
			labels: {
				display: true,
				usePointStyle: true,
				pointStyle : 'circle'
			}
		}
	}
  };

var BarChartOptionsConfigurationValuesOnTop =  {
    responsive: true,
    maintainAspectRatio: false,
    legend: {
        position: 'bottom',
        display: true,

    },
    hover: {
      animationDuration: 0
    },
    animation: {
      onComplete: function () {
            var chart = this;
            var ctx = this.chart.ctx;
            ctx.font = Chart.helpers.fontString(Chart.defaults.global.defaultFontSize, Chart.defaults.global.defaultFontStyle, Chart.defaults.global.defaultFontFamily);
            ctx.textAlign = 'center';
            ctx.textBaseline = 'bottom';
            chart.data.datasets.forEach(function (dataset, i) {
                if (chart.isDatasetVisible(i)) {
                    var meta = chart.controller.getDatasetMeta(i);
                    meta.data.forEach(function (bar, index) {
                        var data = dataset.data[index];
                        ctx.fillText(data, bar._model.x, bar._model.y - 5);
                    });
                }
            });
        }
    },
    title: {
        display: true,
        text: 'aaaaa'
    },
    scales: {
      yAxes: [{
        display: true,
        ticks: {
            beginAtZero: true,
        },
        afterDataLimits(scale) {
          scale.max += 1;
        }
      }],
    }
};

var HorizontalBarChartOptionsConfigurationValuesOnTop =  {
    responsive: true,
    maintainAspectRatio: false,
    legend: {
        position: 'bottom',
        display: true,

    },
    hover: {
      animationDuration: 0
    },
    animation: {
      onComplete: function () {
            var chart = this;
            var ctx = this.chart.ctx;
            ctx.font = Chart.helpers.fontString(Chart.defaults.global.defaultFontSize, Chart.defaults.global.defaultFontStyle, Chart.defaults.global.defaultFontFamily);
            ctx.textAlign = 'center';
            ctx.textBaseline = 'bottom';
            chart.data.datasets.forEach(function (dataset, i) {
                if (chart.isDatasetVisible(i)) {
                    var meta = chart.controller.getDatasetMeta(i);
                    meta.data.forEach(function (bar, index) {
                        var data = dataset.data[index];
                        ctx.fillText(data, bar._model.x, bar._model.y - 5);
                    });
                }
            });
        }
    },
    title: {
        display: true,
        text: 'aaaaa'
    },
    scales: {
      yAxes: [{
        display: true,
        ticks: {
            beginAtZero: true,
        },
        afterDataLimits(scale) {
          scale.max += 1;
        }
      }],
      xAxes: [{
          gridLines: {
            display: false,
          },
          ticks: {
            maxRotation: 0,
            maxTicksLimit: 3,
            beginAtZero: true,
          }
        }],
    }
};

function openModal(message){
	var modal = $('#my_modal');
	modal.find('.modal-message').html(message);
	$('#my_modal').modal('show');
}

function hasClass(element, className) {
    return (' ' + element.className + ' ').indexOf(' ' + className+ ' ') > -1;
}

function show(elementID) {
    var ele = document.getElementById(elementID);
    if (!ele) {
        openModal("no such element");
        return;
    }
	//Hide all except ID
	$('#monkey_content').children().not("#flavor").addClass('d-none');
	
	//Show element
	if($('#'+elementID)){
        $('#'+elementID).removeClass('d-none');
    }
	//Show filter div
	if($('#'+elementID)){
		$('#'+elementID).closest('.card-body').find('.input-group').removeClass('d-none');
	}
	//Get Row ID
    var id_row = ele.id + "_row";
    if($('#'+id_row)){
        //Show row
        $('#'+id_row).removeClass('d-none');
    }
	//Get accordion ID
	var id_accordion = ele.id + "_accordion";
	//show accordion div
    if($(id_accordion)){
        $('#'+id_accordion).removeClass('d-none');
    }
	//hide all issues
	$('[id$="detailed-issues"]').children().addClass('d-none');
	//Get chart ID
    var id_chart = ele.id + "_charts";
    if($('#'+id_chart)){
        //Show element
        $('#'+id_chart).removeClass('d-none');
    }
    //find table
    var found_table = ele.querySelectorAll('table[id][type]:not([id=""])');
    if(found_table.length){
        for (var a = 0; a < found_table.length; a ++){
            var type = found_table[a].getAttribute("type")
            if ((!$.fn.DataTable.isDataTable('#'+found_table[a].id)) && (type == 'asList')){
                InitDatatableAsList(found_table[a].id);
            }
            else if ((!$.fn.DataTable.isDataTable('#'+found_table[a].id)) && (type == 'Normal')){
                InitDatatableNormal(found_table[a].id);
            }
        }
    }
	//adjust
	$.fn.dataTable.tables( {visible: true, api: true} ).columns.adjust();
}

function InitDatatableAsList(ID) {
    var ele = document.getElementById(ID);
    if (!ele) {
        openModal("no such table ID "+ID);
        return;
    }
    $("#"+ID).DataTable({
		lengthChange: false,
		responsive: true,
		aaSorting: [],
		bSort: false,
		info: false,
		paging: false,
		searching: false,
        dom: 'Bfrtip',
        fixedColumns: true,
		fixedHeader: true,
		buttons: {
          dom: {
            container:{
              tag:'div',
              className:'flexcontent'
            },
            buttonLiner: {
              tag: null
            }
          },
		  buttons: [
                    {
                        extend:    'excelHtml5',
                        text:      '<i class="bi bi-file-spreadsheet"></i>',
                        title:'Monkey365 Excel results',
                        titleAttr: 'Excel',
                        className: 'dtbtn dtbtn-app excel',
						messageTop: 'https://github.com/silverhack/monkey365'
                    },
                    {
                        extend:    'csvHtml5',
                        text:      '<i class="bi bi-filetype-csv"></i>',
                        title:'Monkey365 CSV results',
                        titleAttr: 'CSV',
                        className: 'dtbtn dtbtn-app csv'
                    },
					{
                        extend:    'print',
                        text:      '<i class="bi bi-printer-fill"></i>',
                        title:'Monkey365 Print results',
                        titleAttr: 'Print',
                        className: 'dtbtn dtbtn-app print',
						messageTop: 'https://github.com/silverhack/monkey365',
						customize: function ( win ) {
								$(win.document.body)
									.css( 'font-size', '10pt' ) 
								$(win.document.body).find( 'table' )
									.addClass( 'compact' )
									.css( 'font-size', 'inherit' );
							}
                    },
                ],
		}
		}).columns.adjust();
}


function InitDatatableNormal(ID) {
    var ele = document.getElementById(ID);
    if (!ele) {
        openModal("no such table ID "+ID);
        return;
    }
    var oTable = $("#"+ID).DataTable({
		lengthChange: false,
		pageLength: 8,
		responsive: true,
        aaSorting: [],
        paging: true,
        autoWidth: true,
        dom: 'Bfrtip',
		fixedColumns: true,
        columnDefs: [
          {"className": "dt-center", "targets": "_all"}
        ],
		"initComplete": function (settings, json) {  
			$("#"+ID).wrap("<div style='overflow:auto; width:100%;position:relative;'></div>");            
		},
        buttons: {
          dom: {
            container:{
              tag:'div',
              className:'flexcontent'
            },
            buttonLiner: {
              tag: null
            }
          },
		  buttons: [
                    {
                        extend:    'excelHtml5',
                        text:      '<i class="bi bi-file-spreadsheet"></i>',
                        title:'Monkey365 Excel results',
                        titleAttr: 'Excel',
                        className: 'dtbtn dtbtn-app excel',
						messageTop: 'https://github.com/silverhack/monkey365'
                    },
                    {
                        extend:    'csvHtml5',
                        text:      '<i class="bi bi-filetype-csv"></i>',
                        title:'Monkey365 CSV results',
                        titleAttr: 'CSV',
                        className: 'dtbtn dtbtn-app csv'
                    },
					{
                        extend:    'print',
                        text:      '<i class="bi bi-printer-fill"></i>',
                        title:'Monkey365 Print results',
                        titleAttr: 'Print',
                        className: 'dtbtn dtbtn-app print',
						messageTop: 'https://github.com/silverhack/monkey365',
						customize: function ( win ) {
								$(win.document.body)
									.css( 'font-size', '10pt' ) 
								$(win.document.body).find( 'table' )
									.addClass( 'compact' )
									.css( 'font-size', 'inherit' );
							}
                    },
                ],
		}
	}).columns.adjust();
		oTable.columns.adjust().draw();
		oTable.draw();
}