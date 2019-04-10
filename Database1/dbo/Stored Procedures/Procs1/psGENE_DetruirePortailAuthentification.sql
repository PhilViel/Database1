/****************************************************************************************************
Code de service		:		psGENE_DetruirePortailAuthentification
Nom du service		:		Détruire une identification dans le portail.
But					:		Détruire une identification dans le portail.
Facette				:		GENE
Reférence			:		Générique
Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iUserId					L'id à détruire
                        @cCodeDeDestruction			Code à inscrire pour confirmer la destruction

Exemple d'appel:
                exec psGENE_DetruirePortailAuthentification	150071, ''

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------

Historique des modifications :

						Date				Programmeur								Description							Référence
						----------		---------------------------------	----------------------------		---------------
						2011-12-08	Donald Huppé							Création de procédure stockée 
						2012-09-21	Donald Huppé							Mettre bConsentement = 0
						2014-02-20	Pierre-Luc Simard					Ne plus mettre à jour le consentement

SELECT * from tblGENE_PortailAuthentification where iUserId = 260194 
select bConsentement,* from Un_Beneficiary where BeneficiaryID = 260194
						
--exec psGENE_DetruirePortailAuthentification	260194, NULL
						
****************************************************************************************************/

CREATE PROCEDURE dbo.psGENE_DetruirePortailAuthentification(
							   @iUserId int,
                               @cCodeDeDestruction varchar(10) = NULL) -- 'gudule'
AS
	BEGIN

	declare  @ToDelete table(
				iUserId int,
				LastName varchar(75),
				firstname varchar(75),
				Avertissement  varchar(75))
	declare @cCodeDeDestructionToCheck varchar(10)
	
	set @cCodeDeDestructionToCheck = 'gudule'
	
	IF @cCodeDeDestruction is not null and @cCodeDeDestruction <> @cCodeDeDestructionToCheck
	
		begin

			insert INTO @ToDelete select iUserId = null, LastName = '', firstname = '', Avertissement = 'Code de destruction invalide'
			
			SELECT * from @ToDelete
			
			return

		end
	
	if not exists (
			SELECT 
				p.iUserId
			from 
				Mo_Human h
				JOIN tblGENE_PortailAuthentification p ON h.HumanID = p.iUserId
			where 
				h.HumanID = @iUserId 
			)
		
		begin

			insert INTO @ToDelete select iUserId = @iUserId, LastName = '', firstname = '', Avertissement = 'Est inexistant.'
			
			SELECT * from @ToDelete
			
			return

		end

	if isnull(@cCodeDeDestruction,'') <> @cCodeDeDestructionToCheck
		begin

		insert into @ToDelete
		SELECT 
			p.iUserId,
			h.LastName,
			h.firstname,
			Avertissement = 'Est valide.'

		from 
			Mo_Human h
			JOIN tblGENE_PortailAuthentification p ON h.HumanID = p.iUserId
		where 
			h.HumanID = @iUserId 
		end

	else
		BEGIN
		
		insert into @ToDelete
		SELECT 
			p.iUserId,
			h.LastName,
			h.firstname,
			Avertissement = 'Est supprimé.'
		from 
			Mo_Human h
			JOIN tblGENE_PortailAuthentification p ON h.HumanID = p.iUserId
		where 
			h.HumanID = @iUserId 

		-- Détruire l'enregistrement au portail
		delete from tblGENE_PortailAuthentification where iUserId = @iUserId AND @cCodeDeDestruction = @cCodeDeDestructionToCheck
/*
		-- Remettre le consentement du souscripteur à NON
		if exists (SELECT subscriberID FROM dbo.Un_Subscriber where SubscriberID = @iUserId)
			begin
			UPDATE dbo.Un_Subscriber SET bConsentement = 0 where SubscriberID = @iUserId
			end

		-- Remettre le consentement du beneficiaire à NON
		if exists (SELECT BeneficiaryID FROM dbo.Un_Beneficiary where BeneficiaryID = @iUserId)
			begin
			UPDATE dbo.Un_Beneficiary SET bConsentement = 0 where BeneficiaryID = @iUserId
			end
*/
		
		end
	
	SELECT * FROM @ToDelete

	END


