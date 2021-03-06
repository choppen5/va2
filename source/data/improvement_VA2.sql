/* Created by: Index Tuning Wizard 	*/
/* Date: 16-05-2006 			*/
/* Time: 15:22:17 			*/
/* Server Name: CABTAGSB03 			*/
/* Database Name: vadmin21 			*/
/* Workload File Name: C:\Documents and Settings\kiss_ustgo\My Documents\va2trace.trc */


USE [vadmin21] 
go

SET QUOTED_IDENTIFIER ON 
SET ARITHABORT ON 
SET CONCAT_NULL_YIELDS_NULL ON 
SET ANSI_NULLS ON 
SET ANSI_PADDING ON 
SET ANSI_WARNINGS ON 
SET NUMERIC_ROUNDABORT OFF 
go

DECLARE @bErrors as bit

BEGIN TRANSACTION
SET @bErrors = 0

CREATE NONCLUSTERED INDEX [server_task11] ON [dbo].[server_task] ([tk_taskid] ASC, [sv_name] ASC, [sft_elmnt_id] ASC )
IF( @@error <> 0 ) SET @bErrors = 1

IF( @bErrors = 0 )
  COMMIT TRANSACTION
ELSE
  ROLLBACK TRANSACTION


/* Statistics to support recommendations */

CREATE STATISTICS [hind_181575685_2A_4A_12A] ON [dbo].[server_task] ([sv_name], [tk_taskid], [sft_elmnt_id])
