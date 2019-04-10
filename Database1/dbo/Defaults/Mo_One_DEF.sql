CREATE DEFAULT [dbo].[Mo_One_DEF]
    AS 1;


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_RepExceptionType].[RepExceptionTypeVisible]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_AttributeType].[AttributeTypeVisible]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_AttributeType].[AttributeTypeLinkToAll]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_AttributeType].[AttributeTypeMultiple]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_OperType].[CommissionToPay]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_UnitReductionReason].[UnitReductionReasonActive]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_Unit].[WantSubscriberInsurance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_Document].[DocConfirmBeforeSave]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_ChequeType].[ChequeTypeVisible]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_ExternalTransfert].[FullTransfert]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_NoteType].[NoteTypeVisible]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_NoteType].[NoteTypeLinkToAll]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_NoChequeReason].[NoChequeReasonActive]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_IrregularityType].[Active]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_Modal].[PmtByYearID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_Human].[UsingSocialNumber]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_Human].[SharePersonalInfo]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_Human].[MarketingMaterial]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_ChequeSuggestion].[SuggestionAccepted]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_Modal].[BusinessBonusToPay]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_Right].[RightVisible]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_BenefInsur].[BenefInsurPmtByYear]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Mo_UserRight].[Granted]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_RepChargeType].[RepChargeTypeVisible]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_RepChargeType].[RepChargeTypeComm]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[Un_IntReimb].[FullRIN]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[MoBitTrue]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_One_DEF]', @objname = N'[dbo].[MoPmtByYear]';

