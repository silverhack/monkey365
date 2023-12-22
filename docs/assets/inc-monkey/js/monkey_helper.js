//Sidebar collapse function
$(document).ready(function(){
	$("#sidebarCollapse").on('click', function(){
		//adjust
		$("#sidebar").toggleClass('active');
		$($.fn.dataTable.tables(true)).DataTable()
		.columns.adjust();
	})
})


//highlight json data
$(document).ready(function(){
	var objects = $('[id*="monkey_object"]');
	for (var a = 0; a < objects.length; a ++){
		var obj = JSON.parse(objects[a].innerText);
		objects[a].textContent = JSON.stringify(obj, undefined, 4);
	}
	hljs.highlightAll();
})

$('.form-control.finding-filter').on("input", function() {
	var searchVal = $(this).val().toLowerCase();
	//var id = $(this).parents('div').find('.row-data').attr('id');
	var id = $(this).closest('div').next().find('.row-data').attr('id');
	//$('#'+id).children().addClass('d-none');
	$('#'+id).children().filter(function() {
		$(this).toggle($(this).find('.card-header').text().toLowerCase().indexOf(searchVal) > -1)		
	})
});

//Filter button
$('.btn-filter').click(function(e) {
	var value = $(this).attr('data-filter-name').toLowerCase();
	var id = $(this).closest('div').next().find('.row-data').attr('id');
	if(value == 'all'){
		//remove d-none class
		$('#'+id).find('.finding-badge').closest('.monkey-issue-card').removeClass('d-none');
	}
	else{
		$('#'+id).find('.finding-badge').closest('.monkey-issue-card').removeClass('d-none');
		$('#'+id).find('.finding-badge').not('.finding-badge-'+value).closest('.monkey-issue-card').addClass('d-none');
	}
});

jQuery.expr[':'].icontains = function(a, i, m) {
  return jQuery(a).text().toUpperCase()
      .indexOf(m[3].toUpperCase()) >= 0;
};

//Another filter

$(".form-control.search-filter").on("input", function()  {
	var searchVal = $(this).val().toLowerCase();
	if ( searchVal != '' ) {
		$('#monkey_content').children().not("#MonkeyGlobalRow").addClass('d-none');
		$('#MonkeyGlobalRow').removeClass('d-none');
		$('#MonkeyIssues').empty()
		$('[id$="_accordion"]').children().filter(function() {
			if ($(this).find('.card-header').text().toLowerCase().indexOf(searchVal) > -1) {
				newNum = Math.floor(Math.random() * 100);
				var clone = $(this).clone(true).attr('id', 'divInput' + newNum); 
				$(clone).appendTo('#MonkeyIssues'); //Issue is appended
			}
		})
	}
	else{
		$('#MonkeyIssues').empty()
		show('monkey-main-dashboard')
	}
});

//Theme selector
var checkbox = document.querySelector('input[name=theme]');
if(checkbox){
    checkbox.addEventListener('change', function() {
        if(this.checked) {
            trans()
            document.documentElement.setAttribute('data-theme', 'dark');
            Chart.defaults.color = 'rgba(255,255,255,1)'; 
            //Chart.defaults.scale.grid.color = 'rgba(255,255,255,1)';
            //Chart.defaults.scale.grid.color = 'white';
			//Chart.defaults.backgroundColor = 'rgba(255,255,255,1)';
			//Chart.defaults.borderColor = 'rgba(255,255,255,1)';
			Chart.defaults.scale.ticks.color = 'rgba(255,255,255,1)';
			Chart.defaults.scale.ticks.color.fontcolor = 'rgba(255,255,255,1)';
			Chart.defaults.borderColor = "rgba(255,255,255, .2)";
        } else {
            trans()
            document.documentElement.setAttribute('data-theme', 'light')
            Chart.defaults.color = 'rgba(0,0,0,1)';
			Chart.defaults.scale.ticks.color = 'rgba(0,0,0,1)';
			Chart.defaults.scale.ticks.color.fontcolor = 'rgba(0,0,0,1)';
            //Chart.defaults.scale.grid.color = 'rgba(0,0,0,1)';
        }
        
		// Force update to all charts
        Chart.helpers.each(Chart.instances, function(instance){
            //draw background color
            instance.update();
        });
		
		/*
		// Force updates to all charts
		for (let id in Chart.instances) {
			Chart.instances[id].update()
		}
		*/
    })
}

let trans = () => {
    document.documentElement.classList.add('transition');
    window.setTimeout(() => {
        document.documentElement.classList.remove('transition')
    }, 1000)
}

//https://datatables.net/extensions/fixedcolumns/examples/initialisation/size_fixed.html
$(document).ready(function() {
	$('#dashboard_table').DataTable({
		"lengthChange": false,
		"pageLength": 8,
		responsive: true,
        aaSorting: [],
        paging:         true,
        columnDefs: [
          {"className": "dt-center", "targets": "_all"}
        ],
        dom: 'Bfrtip',
        fixedColumns: true,
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
	});
    
    $(".dataTables_filter input")
    .attr("placeholder", "Search here...")
    .css({
      width: "300px",
      display: "inline-block"
    });

} );

//adjust
$.fn.dataTable.tables( {visible: true, api: true} ).columns.adjust();

$('.btn.btn-primary.details-button').click(function(e) {
	//Get issue id 
    var elementId = $(this).attr('data-issue');
	//check if element exists
    var ele = document.getElementById(elementId);
    if (!ele) {
        openModal("no such element");
        return;
    }
    var id_issues = $(ele).closest('.monkey-card-data').attr('id') + "-detailed-issues";
    var id_chart = $(ele).closest('.monkey-card-data').attr('id') + "_charts";
    var id_accordion = $(ele).closest('.monkey-card-data').attr('id') + "_accordion";
	var search = $(ele).closest('.card-body').find('.input-group');
    
	var id = $(ele).closest('.row').attr('id');
	if(id){
		$('#'+id).removeClass('d-none');
	}
	var id_issues = $(ele).closest('.monkey-card-data').attr('id') + "-detailed-issues";
	//hide search div
    if($(search)){
        $(search).addClass('d-none');
    }
    //hide accordion div
    if($(id_accordion)){
        $('#'+id_accordion).addClass('d-none');
    }
    //hide all issues
    $('[id$="detailed-issues"]').addClass('d-none');
    //Show issue
	if($('#'+elementId)){
        //Show detailed issue
        $('#'+elementId).removeClass('d-none');
    }
	$('#MonkeyGlobalRow').addClass('d-none');
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
	//Get detailed issue
    var detailed = document.getElementById(id_issues);
    if(detailed){
		$('#'+detailed.id).removeClass('d-none');
    }
    if($('#'+id_chart)){
        //Hide charts if any
		$('#'+id_chart).addClass('d-none');
    }
    //adjust table if any
	$.fn.dataTable.tables( {visible: true, api: true} ).columns.adjust();
});