create table #commands (
[rowid] int identity(1,1),
[command] varchar(4000),
[rows] bigint
)

--declare @command nvarchar(4000)
--declare @rows bigint

declare @currowid int = 1
declare @maxrowid int
declare @command nvarchar(4000)

--declare stats_cur cursor for
	insert into #commands ([command],[rows])
	SELECT 'update statistics ['+sc.name+'].['+t.name+'] ['+s.name+'] with FULLSCAN, PERSIST_SAMPLE_PERCENT = ON
	' [command], [rows]
	FROM sys.stats AS s   
	CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
	join sys.tables t on t.object_id=s.object_id
	join sys.schemas sc on t.schema_id = sc.schema_id
	where rows is not NULL and is_ms_shipped = 0
	and modification_counter=0
	and rows_sampled/rows*100.00 <100
	
	insert into #commands ([command],[rows])
	SELECT 'update statistics ['+sc.name+'].['+t.name+'] ['+s.name+'] with FULLSCAN, PERSIST_SAMPLE_PERCENT = ON
	' [command], [rows]
	FROM sys.stats AS s   
	CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
	join sys.tables t on t.object_id=s.object_id
	join sys.schemas sc on t.schema_id = sc.schema_id
	where rows is not NULL and is_ms_shipped = 0
	and rows_sampled/rows*100.00 =100
	and (round(sqrt(1000*rows),0))<=modification_counter
	
	insert into #commands ([command],[rows])
	SELECT 'update statistics ['+sc.name+'].['+t.name+'] ['+s.name+'] with FULLSCAN, PERSIST_SAMPLE_PERCENT = ON
	' [command], [rows]
	FROM sys.stats AS s   
	CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
	join sys.tables t on t.object_id=s.object_id
	join sys.schemas sc on t.schema_id = sc.schema_id
	where rows is not NULL and is_ms_shipped = 0
	and cast(round(modification_counter*1.0/rows*100,2) as decimal(10,2))>0
	and rows_sampled/rows*100.00 <100
	order by [rows] asc

select @maxrowid = max([rowid]) from #commands

print @maxrowid

while @currowid<=@maxrowid
begin
	select @command = [command]
	from #commands
	where rowid = @currowid

	--execute sp_executesql @command

	print @command

	set @currowid=@currowid+1
end

drop table #commands

--open stats_cur
--fetch next from stats_cur into @command, @rows

--while @@FETCH_STATUS = 0
--begin
--	--execute sp_executesql @command
--	print @command


--	fetch next from stats_cur into @command, @rows
--end

--close stats_cur
--deallocate stats_cur