
/****************************************************************************************************
Code de service		:		psGENE_SupprimerAuthentification
Nom du service		:		Ce service permet de détruire les enregistrement de la table tblGENE_PortailAuthentification
But					:		Récupérer le type 
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@@iUserId					Identifiant de l’humain
Exemple d'appel:
                
                EXEC dbo.psGENE_SupprimerAuthentification 176465

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-09-06					Eric Michaud							Création du service
						2011-09-26					Donald Huppé							Modifier la valeur du @profile_name
						2011-11-03					Eric Michaud							Insertion d'une note au dossier
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_SupprimerAuthentification]
				(					
					@iUserId INT
				)
AS
	BEGIN

	SET NOCOUNT ON

	declare @mail varchar(500);
	declare @param1 varchar(200);
	declare @param2 varchar(200);
	declare @param3 varchar(200);
	declare @note varchar(200);
		 
	IF EXISTS (SELECT 1 from tblGENE_PortailAuthentification where iUserId = @iUserId AND iEtat <> 0)
	begin
		select @mail = (select 'ID = ' + cast(iUserId as varchar(15)) + '  Code Statut = ' +  cast(iIDEtat AS varchar(1))+ '  Description = ' + vcDescEtat
		from tblGENE_PortailAuthentification,tblGENE_PortailEtat 
		where iUserId = @iUserId AND iEtat = iIDEtat )
		
		SELECT @param1 = dbo.fnGENE_ObtenirParametre('GENE_PORTAILAUTHENTIFICATION_PROFILE_NAME',
																 NULL,NULL,NULL,NULL,NULL,NULL)
		SELECT @param2 = dbo.fnGENE_ObtenirParametre('GENE_PORTAILAUTHENTIFICATION_RECIPIENTS',
																 NULL,NULL,NULL,NULL,NULL,NULL)
		SELECT @param3 = dbo.fnGENE_ObtenirParametre('GENE_PORTAILAUTHENTIFICATION_SUBJECT',
																 NULL,NULL,NULL,NULL,NULL,NULL)
		
		EXEC msdb.dbo.sp_send_dbmail @profile_name = @param1, @recipients = @param2,  @body = @mail , @subject = @param3
	end
	ELSE 
		delete tblGENE_PortailAuthentification
		where iUserId = @iUserId	

		-- insertion d'une note au dossier 
		SELECT @note = dbo.fnGENE_ObtenirParametre('GENE_PORTAILAUTHENTIFICATION_NOTE',
																 NULL,NULL,NULL,NULL,NULL,NULL)

		exec psGENE_InsererNote 2,@iUserId,6,null,0,'Portail-client',@note,NULL,'Note'



	END
