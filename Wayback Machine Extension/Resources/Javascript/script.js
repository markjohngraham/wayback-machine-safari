//safari.self.addEventListener("beforeNavigate", _onBeforeNavigate, true);
//safari.self.addEventListener("navigate", _onNavigate, true);

var IAExtension = function () {
    "use strict";
    var me = {};
    var IAglobvar;

    me.init = function () {
        window.addEventListener("DOMContentLoaded", function(event) {
            safari.extension.dispatchMessage("Hello World!");
            safari.self.addEventListener("message", me.handleMessage);
        });

        window.addEventListener("load", function(event) {
            if (location.href.indexOf("https://www.facebook.com/dialog/return/close") > -1 ||
                location.href.indexOf("https://twitter.com/intent/tweet/complete") > -1) {
                // don't load
            } else {
                me.displayRTContent();
            }
        });

        window.addEventListener("beforeunload", function(event) {
            safari.extension.dispatchMessage("_onBeforeNavigate");
        });
    };

me.handleMessage = function (event) {
    if (event.name == "SHOW_BANNER") {
        checkIt(event.message["url"]);
    } else if (event.name == "RADIAL_TREE") {
        document.getElementById("wayback1996-myModal").style.display = "block";
        document.getElementById("wayback1996-RTloader").style.display = "none";
        displayRadialTree(event.message["url"], event.message["data"]);
    } else if (event.name == "DISPLAY_RT_LOADER") {
        me.displayRTContent();
        document.getElementById("wayback1996-myModal").style.display = "block";
        document.getElementById("wayback1996-RTloader").style.display = "block";
    }
}

var enforceBannerInterval;
var archiveLinkWasClicked = false;
var bannerWasShown = false;
var bannerWasClosed = false;

/**
 * Brute force inline css style reset
 */
function resetStyesInline(el) {
    el.style.margin = 0;
    el.style.padding = 0;
    el.style.border = 0;
    el.style.fontSize = "100%";
    el.style.font = "inherit";
    el.style.fontFamily = "sans-serif";
    el.style.verticalAlign = "baseline";
    el.style.lineHeight = "1";
    el.style.boxSizing = "content-box";
    el.style.overflow = "unset";
    el.style.fontWeight = "inherit";
    el.style.height = "auto";
    el.style.position = "relative";
    el.style.width = "auto";
    el.style.display = "inline";
    el.style.backgroundColor = "transparent";
    el.style.color = "#333";
    el.style.textAlign = "left";
}

/**
 * Communicates with background.js
 * @param action {string}
 * @param complete {function}
 */

/**
 * @param {string} type
 * @param {function} handler(el)
 * @param remaining args are children
 * @returns {object} DOM element
 */
function createEl(type, handler) {
    var el = document.createElement(type);
    resetStyesInline(el);
    
    if (handler !== undefined) {
        handler(el);
    }
    // Append *args to created el
    for (var i = 2; i < arguments.length; i++) {
        el.appendChild(arguments[i]);
    }
    
    return el;
}

me.createBanner = function (wayback_url) {
    if (document.getElementById("wayback1996-no-more-404s-message") !== null) {
        return;
    }
    var bgBtnColor   = "#9A3B38"; // red / was light-blue #0996f8
    var bordBtnColor = "#BF4946"; // light-red / was blue #0675d3
    var darkBtnColor = "#6A2927"; // dark-red / dark-blue #0568ba

    document.body.appendChild(
        createEl("div",
            function(el) {
                el.id = "wayback1996-no-more-404s-message";
                el.style.background = "rgba(0,0,0,.6)";
                el.style.position = "fixed";
                el.style.top = "0";
                el.style.right = "0";
                el.style.bottom = "0";
                el.style.left = "0";
                el.style.zIndex = "999999999";
                el.style.display = "flex";
                el.style.alignItems = "center";
                el.style.justifyContent ="center";
            },
                
            createEl("div",
                function(el) {
                    el.id = "wayback1996-no-more-404s-message-inner";
                    el.style.flex = "0 0 420px";
                    el.style.position = "relative";
                    el.style.top = "0";
                    el.style.padding = "2px";
                    el.style.backgroundColor = "#fff";
                    el.style.borderRadius = "5px";
                    el.style.overflow = "hidden";
                    el.style.display = "flex";
                    el.style.flexDirection = "column";
                    el.style.alignItems = "stretch";
                    el.style.justifyContent ="center";
                    el.style.boxShadow = "0 4px 20px rgba(0,0,0,.5)";
                },
                createEl("div",
                    function(el) {
                        el.id = "wayback1996-no-more-404s-header";
                        el.style.alignItems = "center";
                        el.style.backgroundColor = "#3C3C3C"; // dark-gray
                        el.style.borderBottom = "1px solid #5F5F5F"; // gray
                        el.style.borderRadius = "4px 4px 0 0";
                        el.style.color = "#fff";
                        el.style.display = "flex";
                        el.style.fontSize = "24px";
                        el.style.fontWeight = "700";
                        el.style.height = "54px";
                        el.style.justifyContent = "center";
                        el.appendChild(document.createTextNode("Page not available?"));
                    },
                    createEl("button",
                            function(el) {
                            el.style.position = "absolute";
                            el.style.display = "flex";
                            el.style.alignItems = "center";
                            el.style.justifyContent = "center";
                            el.style.transition = "background-color 150ms";
                            el.style.top = "12px";
                            el.style.right = "16px";
                            el.style.width = "22px";
                            el.style.height = "22px";
                            el.style.borderRadius = "3px";
                            el.style.boxSizing = "border-box";
                            el.style.padding = "0";
                            el.style.border = "none";
                            el.onclick = function() {
                            clearInterval(enforceBannerInterval);
                            document.getElementById("wayback1996-no-more-404s-message").style.display = "none";
                            bannerWasClosed = true;
                            };
                            el.onmouseenter = function() {
                            el.style.backgroundColor = "rgba(0,0,0,.1)";
                            el.style.boxShadow = "0 1px 0 0 rgba(0,0,0,.1) inset";
                            };
                            el.onmousedown = function() {
                            el.style.backgroundColor = "rgba(0,0,0,.2)";
                            el.style.boxShadow = "0 1px 0 0 rgba(0,0,0,.15) inset";
                            };
                            el.onmouseup = function() {
                            el.style.backgroundColor = "rgba(0,0,0,.1)";
                            el.style.boxShadow = "0 1px 0 0 rgba(0,0,0,.1) inset";
                            };
                            el.onmouseleave = function() {
                                el.style.backgroundColor = "transparent";
                                el.style.boxShadow = "";
                            };
                        },
                            
                        createEl("img",
                            function(el) {
                                el.src = safari.extension.baseURI + "close.svg";
                                el.alt = "close";
                                el.style.height = "16px";
                                el.style.transition = "background-color 100ms";
                                el.style.width = "16px";
                                el.style.margin = "0 auto";
                            }
                        )
                    )
                ),
                
                createEl("p", function(el) {
                    el.appendChild(document.createTextNode("View a saved version courtesy of the"));
                    el.style.fontSize = "16px";
                    el.style.margin = "20px 0 4px 0";
                    el.style.textAlign = "center";
                }),
                
                createEl("img", function(el) {
                    el.id = "wayback1996-no-more-404s-image";
                    el.src = safari.extension.baseURI + "car.gif";
                    el.style.height = "auto";
                    el.style.position = "relative";
                    el.style.width = "100%";
                    el.style.boxSizing = "border-box";
                    el.style.padding = "10px 22px"; 
                }),
                
                createEl("a", function(el) {
                    el.id = "wayback1996-no-more-404s-message-link";
                    el.href = wayback_url;
                    el.style.alignItems = "center";
                    el.style.backgroundColor = bgBtnColor;
                    el.style.border = "1px solid " + bordBtnColor;
                    el.style.borderRadius = "3px";
                    el.style.color = "#fff";
                    el.style.display = "flex";
                    el.style.fontSize = "19px";
                    el.style.height = "52px";
                    el.style.justifyContent = "center";
                    el.style.margin = "20px";
                    el.style.textDecoration = "none";
                    el.appendChild(document.createTextNode("Click here to see archived version"));
                    el.onmouseenter = function() {
                    el.style.backgroundColor = bordBtnColor;
                    el.style.border = "1px solid " + darkBtnColor;
                    };
                    el.onmousedown = function() {
                    el.style.backgroundColor = darkBtnColor;
                    el.style.border = "1px solid " + darkBtnColor;
                    };
                    el.onmouseup = function() {
                    el.style.backgroundColor = bordBtnColor;
                    el.style.border = "1px solid " + darkBtnColor;
                    };
                    el.onmouseleave = function() {
                    el.style.backgroundColor = bgBtnColor;
                    el.style.border = "1px solid " + bordBtnColor;
                    };
                    el.onclick = function(e) {
                        archiveLinkWasClicked = true;
                        // Work-around for myspace which hijacks the link
                        if (window.location.hostname.indexOf("myspace.com") >= 0) {
                            e.preventDefault();
                            return false;
                        }
                    };
                })
            )
        )
    );
    // Focus the link for accessibility
    document.getElementById("wayback1996-no-more-404s-message-link").focus();
    
    // Transition element in from top of page
    setTimeout(function() {
               document.getElementById("wayback1996-no-more-404s-message").style.transform = "translate(0, 0%)";
    }, 100);
    
    bannerWasShown = true;
}

function checkIt(wayback_url) {
    // Some pages use javascript to update the dom so poll to ensure
    // the banner gets recreated if it is deleted.
    enforceBannerInterval = setInterval(function() {
        me.createBanner(wayback_url);
    }, 500);
}

me.displayRTContent = function () {
    // if (window.top !== window) return;
    
    if (document.getElementById("wayback1996-myModal") != null) {
        document.getElementById("wayback1996-myModal").remove();
    }
    
    var modal=document.createElement('div');
    modal.setAttribute('id','wayback1996-myModal');
    modal.setAttribute('class','wayback1996-RTmodal');
    
    var modalContent=document.createElement('div');
    modalContent.setAttribute('class','wayback1996-modal-content');
    var span=document.createElement('button');
    var divBtn=document.createElement('div');
    divBtn.setAttribute('id','wayback1996-divBtn');
    var loader = document.createElement("div");
    loader.setAttribute("id", "wayback1996-RTloader");
    loader.style.display = "none";
    var message=document.createElement('div');
    message.setAttribute('id','wayback1996-message');
    
    span.innerHTML='&times;';
    span.setAttribute('class','wayback1996-RTclose');
    
    var main=document.createElement('div');
    var sequence=document.createElement('div');
    var chart=document.createElement('div');
    sequence.setAttribute('id','wayback1996-sequence');
    chart.setAttribute('id','wayback1996-chart');
    main.setAttribute('id','wayback1996-main');
    
    modal.appendChild(divBtn);
    modal.appendChild(loader);
    modal.appendChild(span);
    modal.appendChild(sequence);
    modal.appendChild(chart);
    modal.appendChild(message);
    document.body.appendChild(modal);
    
    modal.style.display = "none";
    
    span.onclick = function() {
        modal.style.display = "none";
    }
}

function displayRadialTree(url, data) {
    // if (window.top !== window) return;

    var paths_arr=new Array();
    var j=0;
    for(var i=1;i<data.length;i++){
      var url=data[i][1].toLowerCase();
      if(url.includes('jpg') || url.includes('pdf') || url.includes('png') || url.includes('form') || url.includes('gif')){
        continue;
      }
/*
      if(url.startsWith('https')){
        url=url.replace('https','http');
      }
*/
      if(data[i][1].indexOf(':80')>(-1)){
        url=data[i][1].replace(':80','');
      }
/*
      if(url.includes('www1')){
        url=url.replace('www1','www');
      }else if(url.includes('www2')){
        url=url.replace('www2','www');
      }else if(url.includes('www3')){
        url=url.replace('www3','www');
      }else if(url.includes('www0')){
          url=url.replace('www0','www');
      }

      if(url.indexOf('://www')==(-1)){
        url="http://www."+url.substring(7);
      }
*/
      var format=/[ !@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/;
      var n=0;
      while(format.test(url.charAt(url.length-1))){
        n++;
        url = url.substring(0, url.length -1);
      }
      
      if(url.charAt(url.length-1)!='/'){
        if(url.charAt(url.length-2)!='/'){
          url=url+'/';
        }else{
          url = url.substring(0, url.length -1);
        }
      }

      if(url.includes('%0a')){
        url.replace('%0a','');
      }
      
      if(url.slice(-2)=='//'){
        url = url.substring(0, url.length -1);
      }

      if(url.includes(',')){
        url=url.replace(/,/g ,'');
      }

      data[i][1]=url;
      if(i==1){
        paths_arr[0]=new Array();
        paths_arr[0].push(data[1]);
      } else if (data[i-1][1]==data[i][1]){
        paths_arr[j].push(data[i]);
      } else {
        j++;
        paths_arr[j]=new Array();
        paths_arr[j].push(data[i]);
      }
    }

    var year_arr=new Array();
    for (var i=0;i<paths_arr.length;i++) {
      year_arr[i]=new Array();
      for(var j=0;j<paths_arr[i].length;j++){
        if (j==0) {
          year_arr[i].push(paths_arr[i][j][1]);
          var date=paths_arr[i][j][0].slice(0,4);
          year_arr[i].push(date);
          
        } else if (paths_arr[i][j-1][0].slice(0,4)!=paths_arr[i][j][0].slice(0,4)) {
          year_arr[i].push(paths_arr[i][j][0].slice(0,4));
        }
      }
    }
    
    var years=new Array();
    
    for(var i=1;i<year_arr[0].length;i++){
      years[i-1]=new Array();
      years[i-1].push(year_arr[0][i]);
    }
    
    for(var i=0;i<year_arr.length;i++){
      var url=year_arr[i][0];
      for(var j=1;j<year_arr[i].length;j++){
        var date=year_arr[i][j];
        var k=0;
        if(years[k]!=undefined){
          while(years[k]!=undefined && years[k][0]!=date){
            k++;
          }
          if(years[k]!=undefined){
            years[k].push(url);
          }
        }
      }
    }
    
    for(var i=0;i<years.length;i++){
      for(var j=1;j<years[i].length;j++){
        var url;
        if(years[i][j].includes('http')){
          url=years[i][j].substring(7);
          
        }else if(years[i][j].includes('https')){
          url=years[i][j].substring(8);
        }
        url=url.slice(0,-1);
        if(url.includes('//')){
          url=url.split('//').join('/');
        }
        url=url.split('/').join('/');
        years[i][j]=url;
      }
    }

    var all_years=[];
    for(var i=0;i<years.length;i++){
      if(years[i].length>1){
        all_years.push(years[i][0]);
      }
    }

    function make_new_text(n){
      var text="";
      var x=2;
      if(years[n].length==2){
        x=1;
      }
      
      for(var i=x;i<years[n].length;i++){
        if(i!=(years[n].length-1)){
          text=text+years[n][i]+" ,1"+"\n";
        }else{
          text=text+years[n][i]+" ,1";
        }
      }

      return text;
    }  

    var divBtn=document.getElementById('wayback1996-divBtn');
    if(document.getElementsByClassName('wayback1996-yearBtn').length==0){
      for(var i=0;i<all_years.length;i++){
        
        var btn=document.createElement('button');
        btn.setAttribute('class','wayback1996-yearBtn');
        btn.setAttribute('value', all_years[i]);
        btn.innerHTML=all_years[i];
        btn.onclick=highlightBtn;
        divBtn.appendChild(btn);
      }
    }

    function highlightBtn(eventObj){
      var target=eventObj.target;
      if(document.getElementsByClassName('wayback1996-activeBtn').length!=0){
        document.getElementsByClassName('wayback1996-activeBtn')[0].classList.remove('wayback1996-activeBtn') ;
      }
      target.classList.add('wayback1996-activeBtn');
      IAglobvar=target.value;
      var num=all_years.indexOf(target.value);
      var text=make_new_text(num);
      make_chart(text);
    }

    var btns=document.getElementsByClassName('wayback1996-yearBtn');
    if(document.getElementsByClassName('wayback1996-activeBtn').length!=0){
      var actId=document.getElementsByClassName('wayback1996-activeBtn')[0].value;
      var index=all_years.indexOf(actId);
      IAglobvar=actId;
      var text=make_new_text(index);
      make_chart(text);
    } else {
      btns[0].classList.add('wayback1996-activeBtn');
      IAglobvar= document.getElementsByClassName('wayback1996-activeBtn')[0].value;
      var text=make_new_text(0);
      make_chart(text);
    }
    
    function make_chart(text){
      document.getElementById('wayback1996-sequence').innerHTML="";
      document.getElementById('wayback1996-chart').innerHTML="";
      document.getElementById('wayback1996-message').innerHTML="";
      var width = window.innerWidth-150;
      var height = window.innerHeight-150;
      var radius = Math.min(width, height) / 2;
      var b = {
        w: 100, h: 30, s: 3, t: 10
      };
      
      var colors=d3.scaleOrdinal(d3.schemeCategory20b);
      var totalSize = 0; 
      var vis = d3.select("#wayback1996-chart").append("svg:svg")
      .attr("width", width)
      .attr("height", height)
      .append("svg:g")
      .attr("id", "wayback1996-container")
      .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
      
      var partition = d3.partition().size([2 * Math.PI, radius * radius]);
      
      var arc = d3.arc()
      .startAngle(function(d) { return d.x0; })
      .endAngle(function(d) { return d.x1; })
      .innerRadius(function(d) { return Math.sqrt(d.y0); })
      .outerRadius(function(d) { return Math.sqrt(d.y1); });
      
      // Use d3.text and d3.csvParseRows so that we do not need to have a header
      // row, and can receive the csv as an array of arrays.
      var csv = d3.csvParseRows(text);
      var json = buildHierarchy(csv);
      console.log(json);
      createVisualization(json);
      
      // Main function to draw and set up the visualization, once we have the data.
      function createVisualization(json) {          
        // Bounding circle underneath the sunburst, to make it easier to detect
        // when the mouse leaves the parent g.
        vis.append("svg:circle")
        .attr("r", radius)
        .style("opacity", 0);
        
        // Turn the data into a d3 hierarchy and calculate the sums.
        var root = d3.hierarchy(json)
        .sum(function(d) { return d.size; })
        .sort(function(a, b) { return b.value - a.value; });
        
        // For efficiency, filter nodes to keep only those large enough to see.
        var nodes = partition(root).descendants()
//          .filter(function(d) {
//            return (d.x1 - d.x0 > 0.005); // 0.005 radians = 0.29 degrees
//          });
        
        var path = vis.data([json]).selectAll("path")
        .data(nodes)
        .enter().append("svg:path")
        .attr("display", function(d) { return d.depth ? null : "none"; })
        .attr("d", arc)
        .attr("fill-rule", "evenodd")
        .style("fill", function(d) { 
          if(d.data.name=='end'){return '#000000';}
          else{
            return colors((d.children ? d : d.parent).data.name); 
          }            
        })
        .style("opacity", 1)
        .style("cursor",'pointer')
        .on("mouseover", mouseover)
        .on("click",openTheUrl);
        // Add the mouseleave handler to the bounding circle.
        d3.select("#wayback1996-container").on("mouseleave", mouseleave);
        
        // Get total size of the tree = value of root node from partition.
        totalSize = path.datum().value;
      };
      
      function openTheUrl(d){
        var year=IAglobvar;
        var anc=d.ancestors().reverse();
        var url="";
        for(var i=1;i<anc.length;i++){
          if(anc[i].data.name == 'end'){
            break;
          }
          url = url+'/'+anc[i].data.name;
        }

        //var wbPath = "/web/" + year + "0630";
        //safari.extension.dispatchMessage("OPEN_URL", {wbPath: wbPath, pageURL: url});
        var fullURL = "https://web.archive.org/web/" + year + "0630" + url;
        window.open(fullURL, '_blank').focus();
      }
      
      // Fade all but the current sequence, and show it in the breadcrumb trail.
      function mouseover(d) {
        var percentage = (100 * d.value / totalSize).toPrecision(3);
        var percentageString = percentage + "%";
        if (percentage < 0.1) {
          percentageString = "< 0.1%";
        }
        
        d3.select("#wayback1996-percentage")
        .text(percentageString);
        
        var sequenceArray = d.ancestors().reverse();
        sequenceArray.shift(); // remove root node from the array
        updateBreadcrumbs(sequenceArray, percentageString);
        
        // Fade all the segments.
        d3.selectAll("path").style("opacity", 0.3);
        
        // Then highlight only those that are an ancestor of the current segment.
        vis.selectAll("path")
        .filter(function(node) {
          return (sequenceArray.indexOf(node) >= 0);
        })
        .style("opacity", 1);
      }
      
      // Restore everything to full opacity when moving off the visualization.
      function mouseleave(d) {
        document.getElementById("wayback1996-sequence").innerHTML="";
        // Deactivate all segments during transition.
        d3.selectAll("path").on("mouseover", null);
        
        // Transition each segment to full opacity and then reactivate it.
        d3.selectAll("path")
        .transition()
        .style("opacity", 1)
        .on("end", function() {
          d3.select(this).on("mouseover", mouseover);
        });
      }
      
      // Generate a string that describes the points of a breadcrumb polygon.
      function breadcrumbPoints(d, i) {
        var points = [];
        points.push("0,0");
        points.push(b.w + ",0");
        points.push(b.w + b.t + "," + (b.h / 2));
        points.push(b.w + "," + b.h);
        points.push("0," + b.h);
        if (i > 0) { // Leftmost breadcrumb; don't include 6th vertex.
        points.push(b.t + "," + (b.h / 2));
      }

      return points.join(" ");
    }
    
    function stash(d) {
      d.x0 = d.x;
      d.dx0 = d.dx;
    }
    
    // Update the breadcrumb trail to show the current sequence and percentage.
    function updateBreadcrumbs(nodeArray, percentageString) {
      var anc_arr=nodeArray;
      // Data join; key function combines name and depth (= position in sequence).
      var trail = document.getElementById("wayback1996-sequence");
      
      var text="";
      var symb=document.createElement('span');
      symb.setAttribute('class','wayback1996-symb');
      symb.innerHTML="/";
      for(var i=0;i<anc_arr.length;i++){
        if(i==0){
          text=" "+anc_arr[i].data.name;
        }else{
          text=text+symb.innerHTML+anc_arr[i].data.name;
        }
      }
      trail.innerHTML=text;        
    }
    
    function drawLegend() {
      // Dimensions of legend item: width, height, spacing, radius of rounded rect.
      var li = {
        w: 75, h: 30, s: 3, r: 3
      };
      
      var legend = d3.select("#wayback1996-legend").append("svg:svg")
      .attr("width", li.w)
      .attr("height", d3.keys(colors).length * (li.h + li.s));
      
      var g = legend.selectAll("g")
      .data(d3.entries(colors))
      .enter().append("svg:g")
      .attr("transform", function(d, i) {
        return "translate(0," + i * (li.h + li.s) + ")";
      });
      
      g.append("svg:rect")
      .attr("rx", li.r)
      .attr("ry", li.r)
      .attr("width", li.w)
      .attr("height", li.h)
      .style("fill", function(d) { return d.value; });
      
      g.append("svg:text")
      .attr("x", li.w / 2)
      .attr("y", li.h / 2)
      .attr("dy", "0.35em")
      .attr("text-anchor", "middle")
      .text(function(d) { return d.key; });
    }
    
    function toggleLegend() {
      var legend = d3.select("#wayback1996-legend");
      if (legend.style("visibility") == "hidden") {
        legend.style("visibility", "");
      } else {
        legend.style("visibility", "hidden");
      }
    }
    
    function buildHierarchy(csv) {
      var length=csv.length;
//        if(length>10000){
//            length=10000;
//            document.getElementById('message').innerHTML="There are "+csv.length;
//        }
      var root = {"name": "root", "children": []};
      for (var i = 0; i < length; i++) {
        var sequence = csv[i][0];
        var size = +csv[i][1];
        if (isNaN(size)) { // e.g. if this is a header row
          continue;
        }
        var parts = sequence.split("/");
        var currentNode = root;
        for (var j = 0; j < parts.length; j++) {
          var children = currentNode["children"];
          var nodeName = parts[j];
          var childNode;
          if (j + 1< parts.length) {
            // Not yet at the end of the sequence; move down the tree.
            var foundChild = false;
            for (var k = 0; k < children.length; k++) {
              if (children[k]["name"] == nodeName) {
                childNode = children[k];
                foundChild = true;
                break;
              }
            }
            // If we don't already have a child node for this branch, create it.
            if (!foundChild) {
              childNode = {"name": nodeName, "children": []};
              children.push(childNode);
            }
            currentNode = childNode;
          } else {
            // Reached the end of the sequence; create a leaf node.
            childNode = {"name": nodeName, "size": size};
            children.push(childNode);
          }
        }
      }
      return root;
    }; 
  }
}

    me.init();
    return me;
}();

