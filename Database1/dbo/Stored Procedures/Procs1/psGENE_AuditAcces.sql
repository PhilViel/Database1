/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc
Code du service:	psGENE_AuditAcces
Nom du service:		Enregistrer une trace des accès effectués sur certaines informations
But:			    Conserver une trace des informations consultées
Facette:		    GENE

Paramètres d’entrée	:	Paramètre				    Description
					    --------------------------	-----------------------------------------------------------------
		  				vcNom_Table                 Nom de la table temporaire dans laquelle récupérer les identifiant
                        vcNom_ChampIdentifiant      Nom du champ qui sert de clé unique
                        vcUtilisateur               Login de l'utilisateur ayant demandé des informations
                        vcContexte                  Contexte de l'action demandé

Exemple d’appel:	EXEC psGENE_AuditAcces '#tGU_RP_SubByEmail', 'SouscripteurId', 'plsimard', GU_RP_SubByEmail 


Paramètres de sortie:		Table						Champ							Description
		  				    -------------------------	--------------------------- 	---------------------------------
							S/O							@Result					        Code de retour standard

Historique des modifications:
						2018-09-25	Pierre-Luc Simard   Création du service

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_AuditAcces](
    @vcNom_Table VARCHAR(75),
    @vcNom_ChampIdentifiant VARCHAR(75),
    @vcUtilisateur VARCHAR(75),
    @vcContexte VARCHAR(75),
    @bAcces_Courriel BIT,
    @bAcces_Telephone BIT,
    @bAcces_Adresse BIT
    )
AS
BEGIN
    
    DECLARE 
        @Result INT = 1,
        @iID_AuditAcces INT,
        @sql VARCHAR(1000) 

	------------------------
	--BEGIN TRANSACTION
	------------------------
	
    IF OBJECT_ID('TEMPDB..' + @vcNom_Table) IS NOT NULL 
    BEGIN 
        -- Ajout de l'audit dans la table tblGENE_AuditAcces
        INSERT INTO tblGENE_AuditAcces (
            dtDate_Acces,
            vcUtilisateur,
            vcNom_Server,
            vcNom_BD,
            vcContexte,
            bAcces_Courriel,
            bAcces_Telephone,
            bAcces_Adresse)
        SELECT 
            dtDate_Acces = GETDATE(),
            vcUtilisateur = @vcUtilisateur,
            vcNom_Server = @@SERVERNAME,
            vcNom_BD = DB_NAME(),
            vcContexte = @vcContexte,
            bAcces_Courriel = @bAcces_Courriel,
            bAcces_Telephone = @bAcces_Telephone,
            bAcces_Adresse = @bAcces_Adresse
    
        IF @@ERROR = 0
	        SET @iID_AuditAcces = SCOPE_IDENTITY()
	    ELSE
            SET @Result = -1

        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        SET @sql = 
            'INSERT INTO tblGENE_AuditHumain(
                iID_Humain,
                iID_AuditAcces)
            SELECT DISTINCT
                iID_Humain = ' + @vcNom_ChampIdentifiant + ',
                iID_AuditAcces = ' + STR(@iID_AuditAcces) + '
            FROM ' + @vcNom_Table + ' R'
         
        EXEC(@sql)
	
	    IF @@ERROR <> 0
            SET @Result = -2

    END 

	/*
	IF @Result > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------
    */
	RETURN @Result
	
END