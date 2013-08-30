<cfcomponent accessors="true" persistent="false" output="false" extends="HibachiTransient">
	
	<!--- Title Information --->
	<cfproperty name="reportTitle" />
	
	<!--- Date / Time Properties --->
	<cfproperty name="reportStartDateTime" hb_formatType="date" />
	<cfproperty name="reportEndDateTime" hb_formatType="date" />
	<cfproperty name="reportCompareStartDateTime" hb_formatType="date" />
	<cfproperty name="reportCompareEndDateTime" hb_formatType="date" />
	<cfproperty name="reportDateTimeGroupBy" />
	<cfproperty name="reportDateTimeDataColumn" />
	<cfproperty name="reportCompareFlag" />
	
	<!--- Definition Properties --->
	<cfproperty name="metricDefinitions" />
	<cfproperty name="dimensionDefinitions" />
	<cfproperty name="reportDateTimeDefinitions" />
	
	<!--- Metric / Dimension States --->
	<cfproperty name="metrics" />
	<cfproperty name="dimensions" />
	<cfproperty name="reportDateTime" />
	
	<!--- Data Properties & Queries ---> 
	<cfproperty name="data" />
	<cfproperty name="chartDataQuery" />
	<cfproperty name="chartData" />
	<cfproperty name="tableDataQuery" />
	
	<!--- Rendered Data Properties --->
	<cfproperty name="reportDataTable" />
	
	<!--- Format Type Method --->
	<cffunction name="getAliasFormatType" access="public" output="false">
		<cfargument name="alias" type="string" required="true" />
		
		<cfif not structKeyExists(variables, "aliasFormatType#arguments.alias#")>
			<cfset variables[ "aliasFormatType#arguments.alias#" ] = "" />
			
			<!--- Check Dimensions --->
			<cfloop array="#getDimensionDefinitions()#" index="dimensionDefinition">
				<cfif dimensionDefinition.alias eq arguments.alias and structKeyExists(dimensionDefinition, 'formatType')>
					<cfset variables[ "aliasFormatType#arguments.alias#" ] = dimensionDefinition.formatType />
					<cfreturn variables[ "aliasFormatType#arguments.alias#" ] />
				<cfelseif dimensionDefinition.alias eq arguments.alias>
					<cfbreak />
				</cfif>
			</cfloop>
			
			<!--- Check Metrics --->
			<cfloop array="#getMetricDefinitions()#" index="metricDefinition">
				<cfif metricDefinition.alias eq arguments.alias and structKeyExists(metricDefinition, 'formatType')>
					<cfset variables[ "aliasFormatType#arguments.alias#" ] = metricDefinition.formatType />
					<cfreturn variables[ "aliasFormatType#arguments.alias#" ] />
				<cfelseif metricDefinition.alias eq arguments.alias>
					<cfbreak />
				</cfif>
			</cfloop>
		</cfif>
		
		<cfreturn variables[ "aliasFormatType#arguments.alias#" ] />
	</cffunction>
	
	<!--- ================= START: QUERY HELPER METHODS ====================== --->
	
	<cffunction name="getReportDateTimeSelect" access="public" output="false">
		<cfset var reportDateTimeSelect="" />
		<cfsavecontent variable="reportDateTimeSelect">
			<cfoutput>
				<cfif getApplicationValue('databaseType') eq "MySQL">
					#getReportDateTimeDefinition(getReportDateTime())['dataColumn']# as reportDateTime,
					YEAR( #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeYear,
					MONTH( #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeMonth,
					WEEK( #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeWeek,
					DAY( #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeDay,
					HOUR( #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeHour
				<cfelse>
					#getReportDateTimeDefinition(getReportDateTime())['dataColumn']# as reportDateTime,
					DATEPART( year, #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeYear,
					DATEPART( month, #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeMonth,
					DATEPART( week, #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeWeek,
					DATEPART( day, #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeDay,
					DATEPART( hour, #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# ) as reportDateTimeHour  
				</cfif>
			</cfoutput>
		</cfsavecontent>
		<cfreturn reportDateTimeSelect />
	</cffunction>
	
	<cffunction name="getReportDateTimeWhere" access="public" output="false">
		<cfset var reportDateTimeWhere="" />
		
		<cfset var startDateTime = replace(replace(createDateTime(dateFormat(getReportStartDateTime(), "yyyy"),datePart("m" , getReportStartDateTime()),datePart("d" , getReportStartDateTime()),0,0,0), '{ts', ''),'}','') />
		<cfset var endDateTime = replace(replace(createDateTime(dateFormat(getReportEndDateTime(), "yyyy"),datePart("m" , getReportEndDateTime()),datePart("d" , getReportEndDateTime()),23,59,59), '{ts', ''),'}','') />
		<cfset var compareStartDateTime = replace(replace(createDateTime(dateFormat(getReportCompareStartDateTime(), "yyyy"),datePart("m" , getReportCompareStartDateTime()),datePart("d" , getReportCompareStartDateTime()),0,0,0), '{ts', ''),'}','') />
		<cfset var compareEndDateTime = replace(replace(createDateTime(dateFormat(getReportCompareEndDateTime(), "yyyy"),datePart("m" , getReportCompareEndDateTime()),datePart("d" , getReportCompareEndDateTime()),23,59,59), '{ts', ''),'}','') />
		<cfsavecontent variable="reportDateTimeWhere">
			<cfoutput>
				(
					(#getReportDateTimeDefinition(getReportDateTime())['dataColumn']# >= #startDateTime# AND #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# <= #endDateTime#)
					<cfif getReportCompareFlag()>
						OR (#getReportDateTimeDefinition(getReportDateTime())['dataColumn']# >= #compareStartDateTime# AND #getReportDateTimeDefinition(getReportDateTime())['dataColumn']# <= #compareEndDateTime#)
					</cfif>
				)
			</cfoutput>
		</cfsavecontent>
		
		<cfreturn reportDateTimeWhere />
	</cffunction>
	
	<!--- =================  END: QUERY HELPER METHODS ======================= --->
	
	<!--- ================= START: TITLE HELPER METHODS ====================== --->
		
	<cffunction name="getReportTitle" access="public" output="false">
		<cfreturn rbKey('report.#getClassName()#') />
	</cffunction>
	
	<cffunction name="getMetricTitle" access="public" output="false">
		<cfargument name="alias" type="string" required="true" />
		
		<cfset var metricDefinition = {} />
		
		<cfloop array="#getMetricDefinitions()#" index="metricDefinition">
			<cfif metricDefinition.alias eq arguments.alias and structKeyExists(metricDefinition, 'title')>
				<cfreturn metricDefinition.title />
			</cfif>
		</cfloop>
		
		<cfreturn rbKey('report.#getClassName()#.#alias#') />
	</cffunction>
	
	<cffunction name="getDimensionTitle" access="public" output="false">
		<cfargument name="alias" type="string" required="true" />
		
		<cfset var dimensionDefinition = {} />
		
		<cfloop array="#getDimensionDefinitions()#" index="dimensionDefinition">
			<cfif dimensionDefinition.alias eq arguments.alias and structKeyExists(dimensionDefinition, 'title')>
		 		<cfreturn dimensionDefinition.title />
			</cfif>
		</cfloop>
		
		<cfreturn rbKey('report.#getClassName()#.#alias#') />
	</cffunction>
	
	<cffunction name="getReportDateTimeTitle" access="public" output="false">
		<cfargument name="alias" type="string" required="true" />
		
		<cfset var reportDateTimeDefinition = {} />
		
		<cfloop array="#getReportDateTimeDefinitions()#" index="reportDateTimeDefinition">
			<cfif reportDateTimeDefinition.alias eq arguments.alias and structKeyExists(reportDateTimeDefinition, 'title')>
		 		<cfreturn reportDateTimeDefinition.title />
			</cfif>
		</cfloop>
		
		<cfreturn rbKey('report.#getClassName()#.#alias#') />
	</cffunction>
		
	<!--- =================  END: TITLE HELPER METHODS ======================= --->
	
	<!--- ================== START: DEFINITION METHODS ======================= --->
		
	<cffunction name="getMetricDefinitions" access="public" output="false">
		<cfreturn [] />
	</cffunction>
	
	<cffunction name="getDimensionDefinitions" access="public" output="false">
		<cfreturn [] />
	</cffunction>
	
	<cffunction name="getReportDateTimeDefinitions" access="public" output="false">
		<cfreturn [] />
	</cffunction>
		
	<cffunction name="getMetricDefinition" access="public" output="false">
		<cfargument name="alias" type="string" required="true" />
		
		<cfset var metricDefinition = structNew() />
		
		<cfloop array="#getMetricDefinitions()#" index="metricDefinition">
			<cfif metricDefinition.alias eq arguments.alias>
				<cfreturn metricDefinition />
			</cfif>
		</cfloop>
	</cffunction>
	
	<cffunction name="getDimensionDefinition" access="public" output="false">
		<cfargument name="alias" type="string" required="true" />
		
		<cfset var dimensionDefinition = structNew() />
		
		<cfloop array="#getDimensionDefinitions()#" index="dimensionDefinition">
			<cfif dimensionDefinition.alias eq arguments.alias>
				<cfreturn dimensionDefinition />
			</cfif>
		</cfloop>
	</cffunction>
	
	<cffunction name="getReportDateTimeDefinition" access="public" output="false">
		<cfargument name="alias" type="string" required="true" />
		
		<cfset var reportDateTimeDefinition = structNew() />
		
		<cfloop array="#getReportDateTimeDefinitions()#" index="reportDateTimeDefinition">
			<cfif reportDateTimeDefinition.alias eq arguments.alias>
				<cfreturn reportDateTimeDefinition />
			</cfif>
		</cfloop>
	</cffunction>
	
	<!--- ==================  END: DEFINITION METHODS ======================== --->
	
	<!--- ================== START: DATE/TIME DEFAULTS ======================= --->

	<cffunction name="getReportStartDateTime" access="public" output="false">
		<cfif not structKeyExists(variables, "reportStartDateTime")>
			<cfset variables.reportStartDateTime = dateFormat(now() - 30, "yyyy-mm-dd") />
		</cfif>
		<cfreturn dateFormat(variables.reportStartDateTime,"yyyy-mm-dd") />
	</cffunction>
	
	<cffunction name="getReportEndDateTime" access="public" output="false">
		<cfif not structKeyExists(variables, "reportEndDateTime")>
			<cfset variables.reportEndDateTime = dateFormat(now(), "yyyy-mm-dd") />
		</cfif>
		<cfreturn dateFormat(variables.reportEndDateTime,"yyyy-mm-dd") />
	</cffunction>
	
	<cffunction name="getReportCompareStartDateTime" access="public" output="false">
		<cfif not structKeyExists(variables, "reportCompareStartDateTime")>
			<cfset variables.reportCompareStartDateTime = dateFormat(getReportCompareEndDateTime() - 30, "yyyy-mm-dd") />
		</cfif>
		<cfreturn dateFormat(variables.reportCompareStartDateTime,"yyyy-mm-dd") />
	</cffunction>
	
	<cffunction name="getReportCompareEndDateTime" access="public" output="false">
		<cfif not structKeyExists(variables, "reportCompareEndDateTime")>
			<cfset variables.reportCompareEndDateTime = dateFormat(getReportStartDateTime()-1, "yyyy-mm-dd") />
		</cfif>
		<cfreturn dateFormat(variables.reportCompareEndDateTime,"yyyy-mm-dd") />
	</cffunction>
	
	<cffunction name="getReportDateTimeGroupBy" access="public" output="false">
		<cfif not structKeyExists(variables, "reportDateTimeGroupBy")>
			<cfset variables.reportDateTimeGroupBy = "day" />
		</cfif>
		<cfreturn variables.reportDateTimeGroupBy />
	</cffunction>
	
	<cffunction name="getReportCompareFlag" access="public" output="false">
		<cfif not structKeyExists(variables, "reportCompareFlag")>
			<cfset variables.reportCompareFlag = 0 />
		</cfif>
		<cfreturn variables.reportCompareFlag />
	</cffunction>
	
	<!--- ==================  END: DATE/TIME DEFAULTS ======================== --->
	
	<!--- ================== START: SELECTION DEFAULTS ======================= --->
		
	<cffunction name="getMetrics" access="public" output="false">
		<cfif not structKeyExists(variables, "metrics")>
			<cfset variables.metrics = getMetricDefinitions()[1].alias />
		</cfif>
		<cfreturn variables.metrics />
	</cffunction>
	
	<cffunction name="getDimensions" access="public" output="false">
		<cfif not structKeyExists(variables, "dimensions")>
			<cfset variables.dimensions = getDimensionDefinitions()[1].alias />
		</cfif>
		<cfreturn variables.dimensions />
	</cffunction>
	
	<cffunction name="getReportDateTime" access="public" output="false">
		<cfif not structKeyExists(variables, "reportDateTime")>
			<cfset variables.reportDateTime = getReportDateTimeDefinitions()[1].alias />
		</cfif>
		<cfreturn variables.reportDateTime />
	</cffunction>
	
	<!--- ==================  END: SELECTION DEFAULTS ======================== --->
	
	<!--- ==================== START: CHART FUNCTIONS ======================== --->
	
	<cffunction name="getChartDataQuery" access="public" output="false">
		<cfif not structKeyExists(variables, "chartDataQuery")>
			
			<cfset var m = 1 />
			<cfset var data = getData() />
			
			<cfquery name="variables.chartDataQuery" dbtype="query">
				SELECT
					<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
						<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
						<cfif m gt 1>,</cfif>
						<cfif structKeyExists(metricDefinition, "calculation")>
							#metricDefinition.calculation# as #metricDefinition.alias#
						<cfelse>
							#metricDefinition.function#(#metricDefinition.alias#) as #metricDefinition.alias#
						</cfif>
					</cfloop>
					<cfif listFindNoCase('year,month,week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeYear
					</cfif>
					<cfif listFindNoCase('month,week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeMonth
					</cfif>
					<cfif listFindNoCase('week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeWeek
					</cfif>
					<cfif listFindNoCase('day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeDay
					</cfif>
					<cfif listFindNoCase('hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeHour
					</cfif>
				FROM
					data
				WHERE
					reportDateTime >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportStartDateTime()#" />
				  AND
				  	reportDateTime <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportEndDateTime()#" />
				GROUP BY
					<cfif listFindNoCase('year,month,week,day,hour', getReportDateTimeGroupBy())>
						data.reportDateTimeYear
					</cfif>
					<cfif listFindNoCase('month,week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeMonth
					</cfif>
					<cfif listFindNoCase('week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeWeek
					</cfif>
					<cfif listFindNoCase('day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeDay
					</cfif>
					<cfif listFindNoCase('hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeHour
					</cfif>
				ORDER BY
					<cfif listFindNoCase('year,month,week,day,hour', getReportDateTimeGroupBy())>
						data.reportDateTimeYear
					</cfif>
					<cfif listFindNoCase('month,week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeMonth
					</cfif>
					<cfif listFindNoCase('week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeWeek
					</cfif>
					<cfif listFindNoCase('day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeDay
					</cfif>
					<cfif listFindNoCase('hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeHour
					</cfif>
			</cfquery>
		</cfif>
		
		<cfreturn variables.chartDataQuery />
	</cffunction>
	
	<cffunction name="getChartCompareDataQuery" access="public" output="false">
		<cfif not structKeyExists(variables, "chartCompareDataQuery")>
			
			<cfset var m = 1 />
			<cfset var data = getData() />
			
			<cfquery name="variables.chartCompareDataQuery" dbtype="query">
				SELECT
					<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
						<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
						<cfif m gt 1>,</cfif>
						<cfif structKeyExists(metricDefinition, "calculation")>
							#metricDefinition.calculation# as #metricDefinition.alias#
						<cfelse>
							#metricDefinition.function#(#metricDefinition.alias#) as #metricDefinition.alias#
						</cfif>
					</cfloop>
					<cfif listFindNoCase('year,month,week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeYear
					</cfif>
					<cfif listFindNoCase('month,week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeMonth
					</cfif>
					<cfif listFindNoCase('week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeWeek
					</cfif>
					<cfif listFindNoCase('day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeDay
					</cfif>
					<cfif listFindNoCase('hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeHour
					</cfif>
				FROM
					data
				WHERE
					reportDateTime >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportCompareStartDateTime()#" />
				  AND
				  	reportDateTime <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportCompareEndDateTime()#" />
				GROUP BY
					<cfif listFindNoCase('year,month,week,day,hour', getReportDateTimeGroupBy())>
						data.reportDateTimeYear
					</cfif>
					<cfif listFindNoCase('month,week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeMonth
					</cfif>
					<cfif listFindNoCase('week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeWeek
					</cfif>
					<cfif listFindNoCase('day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeDay
					</cfif>
					<cfif listFindNoCase('hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeHour
					</cfif>
				ORDER BY
					<cfif listFindNoCase('year,month,week,day,hour', getReportDateTimeGroupBy())>
						data.reportDateTimeYear
					</cfif>
					<cfif listFindNoCase('month,week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeMonth
					</cfif>
					<cfif listFindNoCase('week,day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeWeek
					</cfif>
					<cfif listFindNoCase('day,hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeDay
					</cfif>
					<cfif listFindNoCase('hour', getReportDateTimeGroupBy())>
						,data.reportDateTimeHour
					</cfif>
			</cfquery>
		</cfif>
		
		<cfreturn variables.chartCompareDataQuery />
	</cffunction>
	
	<cffunction name="getMetricColorDetails" access="public" output="false">
		<cfreturn [
			{color="##eb6420",compareColor="##fad8c7"},
			{color="##009800",compareColor="##bfe5bf"},
			{color="##207de5",compareColor="##c7def8"},
			{color="##5319e7",compareColor="##d4c5f9"},
			{color="##fbca04",compareColor="##fef2c0"},
			{color="##006b75",compareColor="##bfdadc"},
			{color="##0052cc",compareColor="##bfd4f2"}
		] />
	</cffunction>
	
	<cffunction name="getChartData" access="public" output="false">
		<cfif not structKeyExists(variables, "chartData")>
			
			<cfset var chartDataStruct = structNew() />
			<cfset var chartDataQuery = getChartDataQuery() />
			<cfif getReportCompareFlag()>
				<cfset var chartCompareDataQuery = getChartCompareDataQuery() />
			</cfif>
			
			<cfset var thisDate = "" />
			<cfset var m = 1 />
			<cfset var loopdatepart = "d" />
			<cfset var weekAdjustment = 0 />
			<cfif getApplicationValue('databaseType') eq "MySQL">
				<cfset var weekAdjustment = 1 />
			</cfif>
			
			<cfif getReportDateTimeGroupBy() eq 'year'>
				<cfset loopdatepart = "yyyy" />
			<cfelseif getReportDateTimeGroupBy() eq 'month'>
				<cfset loopdatepart = "m" />
			<cfelseif getReportDateTimeGroupBy() eq 'week'>
				<cfset loopdatepart = "ww" />
			<cfelseif getReportDateTimeGroupBy() eq 'hour'>
				<cfset loopdatepart = "h" />	
			</cfif>
			
			<cfset variables.chartData = {} />
			<cfset variables.chartData["chart"] = {} />
			<cfset variables.chartData["chart"]["type"] = "line" />
			<cfset variables.chartData["legend"] = {} />
			<cfset variables.chartData["legend"]["enabled"] = false />
			<cfset variables.chartData["title"] = {} />
			<cfset variables.chartData["title"]["text"] = getReportTitle() />
			
			<!--- Setup xAxis --->
			<cfset variables.chartData["xAxis"] = [] />
			<cfset var xAxisData = {} />
			<cfset xAxisData["type"] = "datetime" />
			<cfset arrayAppend(variables.chartData["xAxis"], xAxisData) />
			
			<!--- Setup Compare xAxis --->
			<cfset var xAxisCompareData = {} />
			<cfset xAxisCompareData["type"] = "datetime" />
			<cfset xAxisCompareData["opposite"] = true />
			<cfset arrayAppend(variables.chartData["xAxis"], xAxisCompareData) />
			
			<!--- Setup yAxis --->
			<cfset variables.chartData["yAxis"] = {} />
			<cfset variables.chartData["yAxis"]["title"] = {} />
			<cfset variables.chartData["yAxis"]["title"]["text"] = '' />
			
			<cfset variables.chartData["series"] = [] />
			
			<cfset var dataSeriesID = 0 />
			<cfset var chartRow = 0 />
						
			<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
				
				<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
				
				<cfset chartRow = 1 />
				<cfset dataSeriesID++ />
				
				<!--- Setup Data Series --->
				<cfset arrayAppend(variables.chartData["series"], {})>
				<cfset variables.chartData["series"][dataSeriesID]["name"] = getMetricTitle(metricDefinition.alias) />
				<cfset variables.chartData["series"][dataSeriesID]["data"] = [] />
				<cfset variables.chartData["series"][dataSeriesID]["xAxis"] = 0 />
				<cfset variables.chartData["series"][dataSeriesID]["color"] = getMetricColorDetails()[m]['color'] />
				<cfif m eq 1>
					<cfset variables.chartData["series"][dataSeriesID]["type"] = "area" />
				</cfif>
				
				<cf_HibachiDateLoop index="thisDate" from="#getReportStartDateTime()#" to="#getReportEndDateTime()#" datepart="#loopdatepart#">
					<cfset var thisData = [] />
					<cfset arrayAppend(thisData, dateDiff("s", createdatetime( '1970','01','01','00','00','00' ), dateAdd("h", 1, thisDate))*1000) />
					<cfif year(thisDate) eq chartDataQuery['reportDateTimeYear'][chartRow] and 
							(!listFindNoCase('month,week,day,hour', getReportDateTimeGroupBy()) or month(thisDate) eq chartDataQuery['reportDateTimeMonth'][chartRow]) and
							(!listFindNoCase('week,day,hour', getReportDateTimeGroupBy()) or (week(thisDate) - weekAdjustment) eq chartDataQuery['reportDateTimeWeek'][chartRow]) and
							(!listFindNoCase('day,hour', getReportDateTimeGroupBy()) or day(thisDate) eq chartDataQuery['reportDateTimeDay'][chartRow]) and
							(!listFindNoCase('hour', getReportDateTimeGroupBy()) or hour(thisDate) eq chartDataQuery['reportDateTimeHour'][chartRow])>
						<cfset arrayAppend(thisData, chartDataQuery[ metricDefinition.alias ][ chartRow ]) />
						<cfset chartRow ++ />
					<cfelse>
						<cfset arrayAppend(thisData, 0) />
					</cfif>
					<cfset arrayAppend(variables.chartData["series"][dataSeriesID]["data"], thisData) />
				</cf_HibachiDateLoop>
				
				<!--- Setup Compare data Series --->
				<cfif getReportCompareFlag()>
					
					<cfset chartRow = 1 />
					<cfset dataSeriesID++ />
					
					<cfset arrayAppend(variables.chartData["series"], {})>
					<cfset variables.chartData["series"][dataSeriesID]["name"] = getMetricTitle(metricDefinition.alias) />
					<cfset variables.chartData["series"][dataSeriesID]["data"] = [] />
					<cfset variables.chartData["series"][dataSeriesID]["xAxis"] = 1 />
					<cfset variables.chartData["series"][dataSeriesID]["color"] = getMetricColorDetails()[m]['compareColor'] />
					
					<cf_HibachiDateLoop index="thisDate" from="#getReportCompareStartDateTime()#" to="#getReportCompareEndDateTime()#" datepart="#loopdatepart#">
						<cfset var thisData = [] />
						<cfset arrayAppend(thisData, dateDiff("s", createdatetime( '1970','01','01','00','00','00' ), dateAdd("h", 1, thisDate))*1000) />
						<cfif year(thisDate) eq chartCompareDataQuery['reportDateTimeYear'][chartRow] and 
								(!listFindNoCase('month,week,day,hour', getReportDateTimeGroupBy()) or month(thisDate) eq chartCompareDataQuery['reportDateTimeMonth'][chartRow]) and
								(!listFindNoCase('week,day,hour', getReportDateTimeGroupBy()) or (week(thisDate) - 1) eq chartCompareDataQuery['reportDateTimeWeek'][chartRow]) and
								(!listFindNoCase('day,hour', getReportDateTimeGroupBy()) or day(thisDate) eq chartCompareDataQuery['reportDateTimeDay'][chartRow]) and
								(!listFindNoCase('hour', getReportDateTimeGroupBy()) or hour(thisDate) eq chartCompareDataQuery['reportDateTimeHour'][chartRow])>
							<cfset arrayAppend(thisData, chartCompareDataQuery[ metricDefinition.alias ][ chartRow ]) />
							<cfset chartRow ++ />
						<cfelse>
							<cfset arrayAppend(thisData, 0) />
						</cfif>
						<cfset arrayAppend(variables.chartData["series"][dataSeriesID]["data"], thisData) />
					</cf_HibachiDateLoop>
				</cfif>
			</cfloop>

		</cfif>
		
		<cfreturn variables.chartData />
	</cffunction>
	
	<!--- ====================  END: CHART FUNCTIONS ========================= --->
		
	<!--- ==================== START: TABLE FUNCTIONS ======================== --->
		
	<cffunction name="getTotalsQuery" access="public" output="false">
		<cfif not structKeyExists(variables, "totalsQuery")>
			
			<cfset var m = 1 />
			<cfset var data = getData() />
			
			<cfquery name="variables.totalsQuery" dbtype="query">
				SELECT
					<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
						<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
						<cfif m gt 1>,</cfif>
						<cfif structKeyExists(metricDefinition, "calculation")>
							#metricDefinition.calculation# as #metricDefinition.alias#
						<cfelse>
							#metricDefinition.function#(#metricDefinition.alias#) as #metricDefinition.alias#
						</cfif>
					</cfloop>
				FROM
					data
				WHERE
					reportDateTime >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportStartDateTime()#" />
				  AND
				  	reportDateTime <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportEndDateTime()#" />
			</cfquery>
		</cfif>
		
		<cfreturn variables.totalsQuery />
	</cffunction>
	
	<cffunction name="getCompareTotalsQuery" access="public" output="false">
		<cfif not structKeyExists(variables, "compareTotalsQuery")>
			
			<cfset var m = 1 />
			<cfset var data = getData() />
			
			<cfquery name="variables.compareTotalsQuery" dbtype="query">
				SELECT
					<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
						<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
						<cfif m gt 1>,</cfif>
						<cfif structKeyExists(metricDefinition, "calculation")>
							#metricDefinition.calculation# as #metricDefinition.alias#
						<cfelse>
							#metricDefinition.function#(#metricDefinition.alias#) as #metricDefinition.alias#
						</cfif>
					</cfloop>
				FROM
					data
				WHERE
					reportDateTime >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportCompareStartDateTime()#" />
				  AND
				  	reportDateTime <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportCompareEndDateTime()#" />
			</cfquery>
		</cfif>
		
		<cfreturn variables.compareTotalsQuery />
	</cffunction>
	
	<cffunction name="getTableDataQuery" access="public" output="false">
		<cfif not structKeyExists(variables, "tableDataQuery")>
			
			<cfset var data = getData() />
			<cfset var unsortedData = "" />
			<cfset var unsortedCompareData = "" />
			<cfset var allDimensions = "" />
			<cfset var dataValue = "" />
			<cfset var compareDataValue = "" />
			<cfset var allUnsortedData = "" />
			<cfset var m = 1 />
			<cfset var d = 1 />
			
			<cfquery name="unsortedData" dbtype="query">
				SELECT
					<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
						<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
						<cfif m gt 1>,</cfif>
						<cfif structKeyExists(metricDefinition, "calculation")>
							#metricDefinition.calculation# as #metricDefinition.alias#
						<cfelse>
							#metricDefinition.function#(#metricDefinition.alias#) as #metricDefinition.alias#
						</cfif>
					</cfloop>
					<cfloop from="1" to="#listLen(getDimensions())#" step="1" index="d">
						<cfset var dimensionDefinition = getDimensionDefinition( listGetAt(getDimensions(), d) ) />
						,#dimensionDefinition.alias#
						<cfif structKeyExists(dimensionDefinition, "filterAlias")>
							,#dimensionDefinition.filterAlias#
						</cfif>
					</cfloop>
				FROM
					data
				WHERE
					reportDateTime >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportStartDateTime()#" />
				  AND
				  	reportDateTime <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportEndDateTime()#" />
				GROUP BY
					<cfloop from="1" to="#listLen(getDimensions())#" step="1" index="d">
						<cfset var dimensionDefinition = getDimensionDefinition( listGetAt(getDimensions(), d) ) />
						<cfif d gt 1>,</cfif>
						#dimensionDefinition.alias#
						<cfif structKeyExists(dimensionDefinition, "filterAlias")>
							,#dimensionDefinition.filterAlias#
						</cfif>
					</cfloop>
			</cfquery>
			
			<cfif getReportCompareFlag()>
				<cfquery name="unsortedCompareData" dbtype="query">
					SELECT
						<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
							<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
							<cfif m gt 1>,</cfif>
							<cfif structKeyExists(metricDefinition, "calculation")>
								#metricDefinition.calculation# as #metricDefinition.alias#Compare
							<cfelse>
								#metricDefinition.function#(#metricDefinition.alias#) as #metricDefinition.alias#Compare
							</cfif>
						</cfloop>
						<cfloop from="1" to="#listLen(getDimensions())#" step="1" index="d">
							<cfset var dimensionDefinition = getDimensionDefinition( listGetAt(getDimensions(), d) ) />
							,#dimensionDefinition.alias#
							<cfif structKeyExists(dimensionDefinition, "filterAlias")>
								,#dimensionDefinition.filterAlias#
							</cfif>
						</cfloop>
					FROM
						data
					WHERE
						reportDateTime >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportCompareStartDateTime()#" />
					  AND
					  	reportDateTime <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#getReportCompareEndDateTime()#" />
					GROUP BY
						<cfloop from="1" to="#listLen(getDimensions())#" step="1" index="d">
							<cfset var dimensionDefinition = getDimensionDefinition( listGetAt(getDimensions(), d) ) />
							<cfif d gt 1>,</cfif>
							#dimensionDefinition.alias#
							<cfif structKeyExists(dimensionDefinition, "filterAlias")>
								,#dimensionDefinition.filterAlias#
							</cfif>
						</cfloop>
				</cfquery>
				
				<cfquery name="allDimensions" dbtype="query">
					SELECT DISTINCT
						<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
							<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
							<cfif m gt 1>,</cfif>
							0 as #metricDefinition.alias#
							,0 as #metricDefinition.alias#Compare
						</cfloop>
						<cfloop from="1" to="#listLen(getDimensions())#" step="1" index="d">
							<cfset var dimensionDefinition = getDimensionDefinition( listGetAt(getDimensions(), d) ) />
							,#dimensionDefinition.alias#
							<cfif structKeyExists(dimensionDefinition, "filterAlias")>
								,#dimensionDefinition.filterAlias#
							</cfif>
						</cfloop>
					FROM
						data
				</cfquery>
				
				<cfloop query="allDimensions">
					<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
						<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
						
						<cfquery name="dataValue" dbtype="query">
							SELECT
								#metricDefinition.alias# as dataValue
							FROM
								unsortedData
							WHERE
								<cfloop from="1" to="#listLen(getDimensions())#" step="1" index="d">
									<cfset var dimensionDefinition = getDimensionDefinition( listGetAt(getDimensions(), d) ) />
									<cfif d gt 1>AND</cfif>
									unsortedData.#dimensionDefinition.alias# = '#allDimensions[ dimensionDefinition.alias ][ allDimensions.currentRow ]#'
									<cfif structKeyExists(dimensionDefinition, "filterAlias")>
										AND unsortedData.#dimensionDefinition.filterAlias# = '#allDimensions[ dimensionDefinition.filterAlias ][ allDimensions.currentRow ]#'
									</cfif>
								</cfloop>  
						</cfquery>
						
						<cfquery name="compareDataValue" dbtype="query">
							SELECT
								#metricDefinition.alias#Compare as dataValue
							FROM
								unsortedCompareData
							WHERE
								<cfloop from="1" to="#listLen(getDimensions())#" step="1" index="d">
									<cfset var dimensionDefinition = getDimensionDefinition( listGetAt(getDimensions(), d) ) />
									<cfif d gt 1>AND</cfif>
									unsortedCompareData.#dimensionDefinition.alias# = '#allDimensions[ dimensionDefinition.alias ][ allDimensions.currentRow ]#'
									<cfif structKeyExists(dimensionDefinition, "filterAlias")>
										AND unsortedCompareData.#dimensionDefinition.filterAlias# = '#allDimensions[ dimensionDefinition.filterAlias ][ allDimensions.currentRow ]#'
									</cfif>
								</cfloop>
						</cfquery>
						
						<cfif dataValue.recordCount>
							<cfset querySetCell(allDimensions, "#metricDefinition.alias#", dataValue.dataValue, allDimensions.currentRow) />
						</cfif>
						<cfif compareDataValue.recordCount>
							<cfset querySetCell(allDimensions, "#metricDefinition.alias#Compare", compareDataValue.dataValue, allDimensions.currentRow) />
						</cfif>
					</cfloop>
				</cfloop>
				
				<cfset allUnsortedData = allDimensions />
			<cfelse>
				<cfset allUnsortedData = unsortedData />
			</cfif>
			
			<cfquery name="variables.tableDataQuery" dbtype="query">
				SELECT
					*
				FROM
					allUnsortedData
				ORDER BY
					<cfloop from="1" to="#listLen(getMetrics())#" step="1" index="m">
						<cfset var metricDefinition = getMetricDefinition( listGetAt(getMetrics(), m) ) />
						<cfif m gt 1>,</cfif>#metricDefinition.alias# DESC
					</cfloop>
			</cfquery>
		</cfif>
		
		<cfreturn variables.tableDataQuery />
	</cffunction>
		
	<!--- ====================  END: TABLE FUNCTIONS ========================= --->
	
	<!--- =============== START: CUSTOM TAG OUTPUT METHODS =================== --->
	
	<cffunction name="getReportDataTable" access="public" output="false">
		<cfif(!structKeyExists(variables, "reportDataTable"))>
			<cfsavecontent variable="variables.reportDataTable">
				<cf_HibachiReportDataTable report="#this#">
			</cfsavecontent>
		</cfif>
		
		<cfreturn variables.reportDataTable />
	</cffunction>
	
	<cffunction name="getReportConfigureBar" access="public" output="false">
		<cfif(!structKeyExists(variables, "reportConfigureBar"))>
			<cfsavecontent variable="variables.reportConfigureBar">
				<cf_HibachiReportConfigureBar report="#this#">
			</cfsavecontent>
		</cfif>
		
		<cfreturn variables.reportConfigureBar />
	</cffunction>
	
	<!--- ===============  END: CUSTOM TAG OUTPUT METHODS ==================== --->	
</cfcomponent>