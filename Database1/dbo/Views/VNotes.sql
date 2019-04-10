CREATE VIEW [dbo].[VNotes] AS
select 
	iID_Note,
	cast(tTexte as varchar(max)) as vcDescription, 
	vcTitre, 
	dtDateCreation,
	iID_TypeNote,
	iID_HumainClient,
	iID_HumainCreateur,
	vcTexteLienObjetLie,
	iId_Objetlie,
	iId_TypeObjet,
	iID_HumainModifiant,
	dtDateModification
from tblGENE_note
UNION ALL
select 
	iID_Etape,
	vcEtapeDescription, 
	vcTitre, 
	dtDateEtape,
	NULL,
	(select max(iID_HumainClient) from tblGENE_Note where iId_Objetlie = E.iID_Tache),
	NULL,
	NULL,
	(select MAX(iID_note) from tblGENE_Note where iId_Objetlie = E.iID_Tache),
	3,
	iID_HumainModifiant,
	dtDateModification
from synUnivBase_tblSGRC_EtapeTache E

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'table qui contient les notes et les étapes de tâches.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VNotes';

